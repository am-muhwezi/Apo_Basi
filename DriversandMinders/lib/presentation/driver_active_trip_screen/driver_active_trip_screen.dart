import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/driver_location_service.dart';
import '../../services/native_location_service.dart';
import '../../services/trip_state_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/driver_drawer_widget.dart';
import './widgets/student_list_widget.dart';

class DriverActiveTripScreen extends StatefulWidget {
  const DriverActiveTripScreen({super.key});

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ApiService _apiService = ApiService();
  final DriverLocationService _locationService = DriverLocationService();
  final NativeLocationService _nativeLocationService = NativeLocationService();
  final TripStateService _tripStateService = TripStateService();

  // Trip data
  DateTime _tripStartTime = DateTime.now();
  String _elapsedTime = "00:00:00";
  bool _isLoadingData = true;
  String? _errorMessage;
  int? _currentTripId;
  Timer? _locationUpdateTimer;

  // Real trip data from API
  Map<String, dynamic> _tripData = {};
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _busData;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkForActiveTripAndLoad();
    _startElapsedTimeTimer();
  }

  /// Check if there's actually an active trip before loading data
  Future<void> _checkForActiveTripAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripInProgress = prefs.getBool('trip_in_progress') ?? false;
      final currentTripId = prefs.getInt('current_trip_id');

      if (!tripInProgress || currentTripId == null) {
        // No active trip in local storage

        if (mounted) {
          // Show message and redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('No active trip found. Please start a trip first.'),
                backgroundColor: AppTheme.warningState,
                behavior: SnackBarBehavior.fixed,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver-start-shift-screen',
              (route) => false,
            );
          });
        }
        return;
      }

      // Try to verify with backend
      try {
        final backendTrip = await _apiService.getActiveTrip();

        if (backendTrip == null || backendTrip['status'] != 'in-progress') {
          // Backend says no active trip - clear stale local state

          await _clearTripStateLocally();

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Trip has already ended. Returning to start shift.'),
                  backgroundColor: AppTheme.warningState,
                  behavior: SnackBarBehavior.fixed,
                  duration: Duration(seconds: 3),
                ),
              );

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/driver-start-shift-screen',
                (route) => false,
              );
            });
          }
          return;
        }

        // Backend confirms trip is active - proceed with loading
        await _loadTripData();
        await _initializeLocationTracking();
      } catch (e) {
        // Network error - trust local state but warn user

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cannot verify trip status with server. Using local data.'),
              backgroundColor: AppTheme.warningState,
              behavior: SnackBarBehavior.fixed,
              duration: Duration(seconds: 3),
            ),
          );
        }

        await _loadTripData();
        await _initializeLocationTracking();
      }
    } catch (e) {
      // Error checking trip state - redirect to be safe
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading trip. Please try again.'),
              backgroundColor: AppTheme.criticalAlert,
              behavior: SnackBarBehavior.fixed,
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/driver-start-shift-screen',
            (route) => false,
          );
        });
      }
    }
  }

  Future<void> _initializeLocationTracking() async {
    try {
      // Get credentials from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final busId = prefs.getInt('current_bus_id');
      final apiUrl = ApiConfig.apiBaseUrl;

      if (token == null || busId == null) {
        return;
      }

      // Save trip state for persistence
      await _tripStateService.saveTripState(
        tripId: _currentTripId ?? DateTime.now().millisecondsSinceEpoch,
        tripType: 'active',
        startTime: _tripStartTime,
        busId: busId,
        busNumber: _busData?['bus_number'] ?? 'BUS-$busId',
      );

      // Start native background location service
      await _nativeLocationService.startLocationTracking(
        token: token,
        busId: busId,
        apiUrl: apiUrl,
      );

      // Also start Flutter location service for map display
      await _locationService.initialize();
      await _locationService.setBusId(busId);
      if (_currentTripId != null) {
        await _locationService.setTripId(_currentTripId);
      }
      await _locationService.startTracking();

      // Start periodic location updates to trip API
      _startLocationUpdateTimer();
    } catch (e) {
      // Silently handle error
    }
  }

  void _startLocationUpdateTimer() {
    // Trip-level HTTP updates are now handled inside DriverLocationService
    // via a background timer keyed by current_trip_id.
    // This method is kept for backwards compatibility/no-op.
  }

  Future<void> _loadTripData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // Get trip state from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentTripId = prefs.getInt('current_trip_id');
      final tripStartTimeStr = prefs.getString('trip_start_time');

      if (tripStartTimeStr != null) {
        _tripStartTime = DateTime.parse(tripStartTimeStr);
      }

      // Get user info from SharedPreferences
      final userName = prefs.getString('user_name') ?? 'Driver';

      // Fetch bus and route data from API
      final busResponse = await _apiService.getDriverBus();
      final routeResponse = await _apiService.getDriverRoute();

      // Extract bus data
      _busData = busResponse['buses'] is Map
          ? busResponse['buses'] as Map<String, dynamic>
          : (busResponse['buses'] is List &&
                  (busResponse['buses'] as List).isNotEmpty
              ? busResponse['buses'][0] as Map<String, dynamic>
              : null);

      // Get trip type from SharedPreferences
      final tripType = prefs.getString('current_trip_type') ?? 'pickup';

      // Build trip data object
      _tripData = {
        "tripId":
            "TRP_${DateTime.now().toString().substring(0, 10).replaceAll('-', '')}_${_busData?['id'] ?? '001'}",
        "trip_type": tripType,
        "routeNumber": routeResponse['route_name']?.toString() ?? "N/A",
        "routeName": routeResponse['route_name'] ?? 'No Route',
        "driverName": userName,
        "busNumber": _busData?['bus_number'] ?? 'N/A',
        "startTime":
            "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        "estimatedEndTime": routeResponse['estimated_duration'] ?? 'N/A',
        "totalDistance": routeResponse['total_distance']?.toString() ?? 'N/A',
        "stops": [], // Populate from route if available
      };

      // Extract and convert children data to students list
      if (routeResponse['children'] != null &&
          routeResponse['children'] is List) {
        final Map<String, Map<String, dynamic>> byId = {};
        for (var child in routeResponse['children']) {
          final String id = child['id']?.toString() ?? '';
          if (id.isEmpty) continue;

          // Extract grade and strip 'Grade' prefix if already present
          String gradeValue = child['grade']?.toString() ??
              child['class_grade']?.toString() ??
              'N/A';
          if (gradeValue.toLowerCase().startsWith('grade')) {
            gradeValue = gradeValue.substring(5).trim();
          }

          byId[id] = {
            "id": id,
            "name": '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
            "grade": gradeValue,
            "stopName": child['address']?.toString() ?? 'No address',
            "parentContact": child['emergency_contact']?.toString() ??
                child['parent_contact']?.toString() ??
                'N/A',
            "specialNotes": child['special_needs']?.toString() ?? '',
            "isPickedUp": false,
          };
        }

        _students = byId.values.toList();
      }

      setState(() {
        _isLoadingData = false;
      });

      // Drivers use REST API to push location, not Socket.IO
      // Socket.IO is only needed for parents to receive real-time updates
      // No need to initialize socket connection for drivers
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load trip data: ${e.toString()}';
        _isLoadingData = false;
        // Keep UI functional with minimal data
        _tripData = {
          "tripId": "N/A",
          "routeNumber": "N/A",
          "routeName": "No Route",
          "driverName": "Driver",
          "busNumber": "N/A",
          "startTime":
              "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          "estimatedEndTime": "N/A",
          "totalDistance": "N/A",
          "stops": [],
        };
        _students = [];
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationUpdateTimer?.cancel();
    // Don't stop location tracking on dispose - it should persist until trip ends
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _startElapsedTimeTimer() {
    // Update elapsed time every second
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        final elapsed = DateTime.now().difference(_tripStartTime);
        final hours = elapsed.inHours.toString().padLeft(2, '0');
        final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

        setState(() {
          _elapsedTime = "$hours:$minutes:$seconds";
        });

        _startElapsedTimeTimer();
      }
    });
  }

  Future<void> _onPickupStatusChanged(int index, bool isPickedUp) async {
    // Update local state immediately for responsiveness
    setState(() {
      _students[index]["isPickedUp"] = isPickedUp;
    });

    // Sync with backend
    try {
      final studentId = _students[index]["id"];
      final prefs = await SharedPreferences.getInstance();
      final tripType = prefs.getString('current_trip_type') ?? 'pickup';

      await _apiService.markAttendance(
        childId: studentId,
        status: isPickedUp ? 'picked_up' : 'pending',
        tripType: tripType,
      );

      // Show success confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    isPickedUp
                        ? '${_students[index]["name"]} marked as picked up'
                        : '${_students[index]["name"]} marked as not picked up',
                  ),
                ),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.successAction,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      // Show error but keep local state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text('Saved locally. Will sync when online.'),
                ),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: AppTheme.warningState,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  void _onEndTripPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Trip'),
        content: Text(
            'Are you sure you want to end this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endTrip();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalAlert,
            ),
            child: Text('End Trip'),
          ),
        ],
      ),
    );
  }

  Future<void> _endTrip() async {
    HapticFeedback.mediumImpact();

    if (_currentTripId == null) {
      // Still try to clear local state if somehow we got here without a trip ID
      await _clearTripStateLocally();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/driver-start-shift-screen',
          (route) => false,
        );
      }
      return;
    }

    // Calculate statistics
    final totalStudents = _students.length;
    final studentsCompleted =
        _students.where((s) => s["isPickedUp"] as bool? ?? false).length;
    final studentsAbsent = totalStudents - studentsCompleted;

    try {
      // Call backend to end trip
      await _apiService.endTrip(
        tripId: _currentTripId!,
        totalStudents: totalStudents,
        studentsCompleted: studentsCompleted,
        studentsAbsent: studentsAbsent,
        studentsPending: 0,
      );

      // Backend confirmed - now clean up local state
      await _clearTripStateLocally();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip ended successfully'),
            backgroundColor: AppTheme.successAction,
            behavior: SnackBarBehavior.fixed,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Navigate back to start shift screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/driver-start-shift-screen',
          (route) => false,
        );
      }
    } catch (e) {
      // Show error with option to force end trip locally
      if (mounted) {
        final shouldForceEnd = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.criticalAlert),
                SizedBox(width: 2.w),
                Expanded(child: Text('Failed to End Trip')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not connect to server to end trip:'),
                SizedBox(height: 1.h),
                Text(
                  e.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.warningState.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningState),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Options:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '• Try Again: Attempt to end trip again\n• Force End Locally: Stop timer and location tracking, clear local state (trip data may be lost)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Try Again'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningState,
                ),
                child: Text('Force End Locally'),
              ),
            ],
          ),
        );

        if (shouldForceEnd == true) {
          // User chose to force end locally
          await _clearTripStateLocally();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Trip ended locally. Location tracking stopped.'),
                backgroundColor: AppTheme.warningState,
                behavior: SnackBarBehavior.fixed,
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver-start-shift-screen',
              (route) => false,
            );
          }
        }
        // If shouldForceEnd is false/null, user will try again - stay on current screen
      }
    }
  }

  /// Clears trip state locally (SharedPreferences, services, timers)
  Future<void> _clearTripStateLocally() async {
    // Stop native background location service
    try {
      await _nativeLocationService.stopLocationTracking();
    } catch (e) {
      // Silently handle error
    }

    // Stop Flutter location tracking
    try {
      await _locationService.stopTracking();
    } catch (e) {
      // Silently handle error
    }

    // Cancel location update timer
    _locationUpdateTimer?.cancel();

    // Clear trip state from TripStateService
    try {
      await _tripStateService.clearTripState();
    } catch (e) {
      // Silently handle error
    }

    // Clear trip state from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_trip_id');
      await prefs.remove('current_trip_type');
      await prefs.remove('trip_start_time');
      await prefs.setBool('trip_in_progress', false);
    } catch (e) {
      // Silently handle error
    }
  }

  // Socket info dialog removed - drivers use REST API for location push, not Socket.IO

  int get _studentsPickedUp =>
      _students.where((s) => s["isPickedUp"] as bool? ?? false).length;

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 7.w,
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        drawer: DriverDrawerWidget(
          currentRoute: '/driver-active-trip-screen',
          driverData: {
            'name': _tripData['driver_name'] ?? 'Driver',
            'bus_number':
                _busData?['bus_number'] ?? _busData?['number_plate'] ?? 'N/A',
          },
          hasActiveTrip: true,
        ),
        appBar: CustomAppBar(
          title: _tripData["trip_type"] == 'pickup'
              ? 'Pickup Trip'
              : 'Dropoff Trip',
          subtitle: '$_studentsPickedUp/${_students.length} • $_elapsedTime',
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: AppTheme.textOnPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.home_outlined, color: AppTheme.textOnPrimary),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/driver-start-shift-screen',
                  (route) => false,
                );
              },
              tooltip: 'Back to Start',
            ),
          ],
        ),
        body: _isLoadingData
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryDriver),
                    SizedBox(height: 2.h),
                    Text(
                      'Loading trip data...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await _loadTripData();
                  },
                  color: AppTheme.primaryDriver,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show error message if API failed
                        if (_errorMessage != null)
                          Container(
                            margin: EdgeInsets.all(4.w),
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    'Running in offline mode',
                                    style: TextStyle(
                                        color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Trip summary card
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 2.h),
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryDriver.withValues(alpha: 0.1),
                                AppTheme.primaryDriver.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppTheme.primaryDriver.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                icon: Icons.people_outline,
                                label: 'Total',
                                value: _students.length.toString(),
                                color: AppTheme.primaryDriver,
                              ),
                              Container(
                                width: 1,
                                height: 8.h,
                                color: AppTheme.borderLight,
                              ),
                              _buildStatItem(
                                icon: Icons.check_circle_outline,
                                label: 'Completed',
                                value: _studentsPickedUp.toString(),
                                color: AppTheme.successAction,
                              ),
                              Container(
                                width: 1,
                                height: 8.h,
                                color: AppTheme.borderLight,
                              ),
                              _buildStatItem(
                                icon: Icons.pending_outlined,
                                label: 'Remaining',
                                value: (_students.length - _studentsPickedUp)
                                    .toString(),
                                color: AppTheme.warningState,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 2.h),

                        // Student list
                        StudentListWidget(
                          students: _students,
                          onPickupStatusChanged: _onPickupStatusChanged,
                        ),

                        SizedBox(height: 12.h), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ),
        // No floating action buttons on the active trip screen
        bottomSheet: Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPrimary,
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                offset: Offset(0, -2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _onEndTripPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalAlert,
                foregroundColor: AppTheme.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'stop_circle',
                    color: AppTheme.textOnPrimary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'End Trip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
