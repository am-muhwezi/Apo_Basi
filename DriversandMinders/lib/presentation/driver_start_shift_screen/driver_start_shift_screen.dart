import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/native_location_service.dart';
import '../../services/trip_state_service.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import './widgets/begin_route_button_widget.dart';
import './widgets/driver_header_widget.dart';
import './widgets/gps_status_widget.dart';
import './widgets/location_services_widget.dart';
import './widgets/pre_trip_checklist_widget.dart';
import './widgets/route_assignment_card_widget.dart';
import './widgets/route_details_modal_widget.dart';
import '../driver_active_trip_screen/driver_active_trip_screen.dart';

class DriverStartShiftScreen extends StatefulWidget {
  const DriverStartShiftScreen({super.key});

  @override
  State<DriverStartShiftScreen> createState() => _DriverStartShiftScreenState();
}

class _DriverStartShiftScreenState extends State<DriverStartShiftScreen> {
  bool _isGpsConnected = false;
  bool _isLocationEnabled = false;
  bool _isChecklistComplete = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String _currentTime = '';
  String _accuracyText = 'Searching...';
  Timer? _timeTimer;
  StreamSubscription<Position>? _positionStream;
  final ApiService _apiService = ApiService();
  final TripStateService _tripStateService = TripStateService();
  final NativeLocationService _nativeLocationService = NativeLocationService();

  // Driver data fetched from API
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _busData;
  Map<String, dynamic>? _routeDetails;
  List<Map<String, dynamic>> _assignedChildren = [];
  String? _errorMessage;

  // Trip state
  bool _hasActiveTrip = false;
  Map<String, dynamic>? _activeTripInfo;

  final List<Map<String, dynamic>> _checklistItems = [
    {
      "title": "Vehicle Exterior Inspection",
      "description": "Check tires, lights, mirrors, and body damage"
    },
    {
      "title": "Interior Safety Check",
      "description":
          "Verify emergency exits, first aid kit, and fire extinguisher"
    },
    {
      "title": "Engine and Fluids",
      "description": "Check oil, coolant, brake fluid levels"
    },
    {
      "title": "Communication Equipment",
      "description": "Test radio and emergency communication devices"
    },
    {
      "title": "Student Safety Equipment",
      "description": "Verify seat belts, safety barriers, and stop sign arm"
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimeUpdates();
    _checkLocationPermission();
    _loadDriverData();
    _checkForActiveTrip();
  }

  Future<void> _checkForActiveTrip() async {
    try {
      // First check local state
      final hasLocalTrip = await _tripStateService.hasActiveTrip();
      final localTripInfo = await _tripStateService.getActiveTripInfo();

      print('📱 Local storage says trip active: $hasLocalTrip');

      if (hasLocalTrip) {
        // Local storage thinks there's an active trip
        // Verify with backend to ensure it's actually still in-progress
        print('🔍 Verifying trip state with backend...');

        try {
          final backendTrip = await _apiService.getActiveTrip();

          if (backendTrip != null && backendTrip['status'] == 'in-progress') {
            // Backend confirms trip is active
            print('✅ Backend confirms active trip (ID: ${backendTrip['id']})');

            setState(() {
              _hasActiveTrip = true;
              _activeTripInfo = localTripInfo;
            });

            // Update local storage with backend trip ID in case it's out of sync
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('current_trip_id', backendTrip['id']);
          } else {
            // Backend says no active trip - local state is stale
            print('⚠️ Backend says no active trip - clearing stale local state');

            await _clearStaleLocalTripState();

            setState(() {
              _hasActiveTrip = false;
              _activeTripInfo = null;
            });
          }
        } catch (e) {
          print('⚠️ Could not verify with backend: $e');

          // Network error - trust local state for now but warn user
          setState(() {
            _hasActiveTrip = true;
            _activeTripInfo = localTripInfo;
          });

          // Show warning that we're in offline mode
          if (mounted) {
            Future.delayed(Duration(seconds: 1), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot verify trip state with server. Using local data.'),
                    backgroundColor: AppTheme.warningState,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      } else {
        // No local trip state
        print('✅ No local trip state found');
        setState(() {
          _hasActiveTrip = false;
          _activeTripInfo = null;
        });
      }
    } catch (e) {
      print('❌ Error checking for active trip: $e');
      setState(() {
        _hasActiveTrip = false;
        _activeTripInfo = null;
      });
    }
  }

  /// Clear stale local trip state when backend says there's no active trip
  Future<void> _clearStaleLocalTripState() async {
    print('🧹 Clearing stale local trip state...');

    try {
      await _tripStateService.clearTripState();
    } catch (e) {
      print('⚠️ Error clearing TripStateService: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_trip_id');
      await prefs.remove('current_trip_type');
      await prefs.remove('trip_start_time');
      await prefs.setBool('trip_in_progress', false);
    } catch (e) {
      print('⚠️ Error clearing SharedPreferences: $e');
    }

    print('✅ Stale local trip state cleared');
  }

  Future<void> _continueTrip() async {
    // Navigate directly to active trip screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverActiveTripScreen(),
      ),
    );
  }

  String _formatTripDuration() {
    if (_activeTripInfo == null || _activeTripInfo!['startTime'] == null) {
      return '0 min';
    }

    final startTime = _activeTripInfo!['startTime'] as DateTime;
    final duration = DateTime.now().difference(startTime);

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes} min';
    }
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // Get user info and cached login data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Driver';
      final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

      // Check if we have cached bus and route data from login
      final cachedBusData = prefs.getString('cached_bus_data');
      final cachedRouteData = prefs.getString('cached_route_data');

      if (cachedBusData != null && cachedRouteData != null) {
        // Use cached data from login response
        try {
          final busDataJson = jsonDecode(cachedBusData);
          final routeDataJson = jsonDecode(cachedRouteData);

          _busData = busDataJson is Map<String, dynamic> ? busDataJson : null;
          _routeDetails = routeDataJson is Map<String, dynamic> ? routeDataJson : null;

          // Extract assigned children list
          if (_routeDetails?['children'] != null && _routeDetails!['children'] is List) {
            _assignedChildren = [];
            for (var child in _routeDetails!['children']) {
              _assignedChildren.add({
                'id': child['id']?.toString() ?? '',
                'name': '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
                'grade': child['grade']?.toString() ?? child['class_grade']?.toString() ?? 'N/A',
                'address': child['address']?.toString() ?? 'No address',
                'phone': child['emergency_contact']?.toString() ?? child['parent_contact']?.toString() ?? '',
              });
            }
          }

          // Build driver data object
          _driverData = {
            "driverId": userId,
            "driverName": userName,
            "busNumber": _busData?['bus_number'] ?? 'No Bus',
            "busPlate": _busData?['number_plate'] ?? 'N/A',
            "routeName": _routeDetails?['route_name'] ?? 'No Route',
            "routeAssignment": '${_busData?['bus_number'] ?? 'No Bus'}${_routeDetails?['route_name'] != null ? ' - ${_routeDetails!['route_name']}' : ''}',
            "estimatedDuration": _routeDetails?['estimated_duration'] ?? "N/A",
            "studentCount": _routeDetails?['total_children'] ?? 0,
          };

          setState(() {
            _isLoadingData = false;
          });
          return;
        } catch (e) {
          print('Error parsing cached data: $e');
          // Fall through to fetch fresh data
        }
      }

      // No cached data or parsing failed - fetch from API
      try {
        final busResponse = await _apiService.getDriverBus();
        final routeResponse = await _apiService.getDriverRoute();

        // Extract bus data
        _busData = busResponse['buses'] is Map
            ? busResponse['buses'] as Map<String, dynamic>
            : (busResponse['buses'] is List &&
                    (busResponse['buses'] as List).isNotEmpty
                ? busResponse['buses'][0] as Map<String, dynamic>
                : null);

        // Extract route data
        _routeDetails = routeResponse;

        // Cache the data for faster future loads
        await prefs.setString('cached_bus_data', jsonEncode(_busData));
        await prefs.setString('cached_route_data', jsonEncode(_routeDetails));

        // Extract assigned children list
        if (routeResponse['children'] != null && routeResponse['children'] is List) {
          _assignedChildren = [];
          for (var child in routeResponse['children']) {
            _assignedChildren.add({
              'id': child['id']?.toString() ?? '',
              'name': '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
              'grade': child['grade']?.toString() ?? child['class_grade']?.toString() ?? 'N/A',
              'address': child['address']?.toString() ?? 'No address',
              'phone': child['emergency_contact']?.toString() ?? child['parent_contact']?.toString() ?? '',
            });
          }
        }

        // Build driver data object
        _driverData = {
          "driverId": userId,
          "driverName": userName,
          "busNumber": _busData?['bus_number'] ?? 'No Bus',
          "busPlate": _busData?['number_plate'] ?? 'N/A',
          "routeName": routeResponse['route_name'] ?? 'No Route',
          "routeAssignment": '${_busData?['bus_number'] ?? 'No Bus'}${routeResponse['route_name'] != null ? ' - ${routeResponse['route_name']}' : ''}',
          "estimatedDuration": routeResponse['estimated_duration'] ?? "N/A",
          "studentCount": routeResponse['total_children'] ?? 0,
        };
      } catch (apiError) {
        // API call failed, use fallback data
        print('API Error: $apiError');
        await _initializeFallbackData();

        // Check if this is a "not assigned" error vs a connection error
        final errorString = apiError.toString();
        if (errorString.contains('not assigned') || errorString.contains('404')) {
          // Driver is not assigned to a bus - this is a valid state, not an error
          setState(() {
            _errorMessage = null; // Don't show error, just show not assigned state
          });
        } else {
          // Real connection error
          setState(() {
            _errorMessage =
                'Could not connect to server. Using offline mode.\n${errorString}';
          });
        }
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load driver data: ${e.toString()}';
        _isLoadingData = false;

        // Fallback to minimal data from SharedPreferences
        _initializeFallbackData();
      });
    }
  }

  Future<void> _initializeFallbackData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Driver';
    final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

    setState(() {
      _driverData = {
        "driverId": userId,
        "driverName": userName,
        "busNumber": "Not Assigned",
        "busPlate": "N/A",
        "routeName": "Awaiting Assignment",
        "routeAssignment": "Not Assigned Yet",
        "estimatedDuration": "N/A",
        "studentCount": 0,
      };

      _routeDetails = {
        "routeName": "Awaiting Assignment",
        "totalDistance": "N/A",
        "estimatedTime": "N/A",
        "totalStops": 0,
        "totalStudents": 0,
        "keyStops": [],
      };

      _assignedChildren = [];
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _startTimeUpdates() {
    _updateCurrentTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCurrentTime();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Permission.location.status;
      if (permission.isGranted) {
        await _enableLocationServices();
      }
    } catch (e) {
      // Handle permission check error silently
    }
  }

  Future<void> _toggleLocationServices() async {
    if (_isLocationEnabled) {
      await _disableLocationServices();
    } else {
      await _enableLocationServices();
    }
  }

  Future<void> _enableLocationServices() async {
    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        _showPermissionDialog();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      setState(() {
        _isLocationEnabled = true;
        _accuracyText = 'Acquiring GPS...';
      });

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          setState(() {
            _isGpsConnected = true;
            _accuracyText = '±${position.accuracy.toInt()}m';
          });
        },
        onError: (error) {
          setState(() {
            _isGpsConnected = false;
            _accuracyText = 'GPS Error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLocationEnabled = false;
        _isGpsConnected = false;
        _accuracyText = 'Location Error';
      });
    }
  }

  Future<void> _disableLocationServices() async {
    _positionStream?.cancel();
    setState(() {
      _isLocationEnabled = false;
      _isGpsConnected = false;
      _accuracyText = 'Disabled';
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
            'Location access is required to track the bus route and ensure student safety. Please enable location permission in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
            'Please enable location services in your device settings to use GPS tracking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _onChecklistComplete(bool isComplete) {
    setState(() {
      _isChecklistComplete = isComplete;
    });
  }

  void _showRouteDetailsModal() {
    if (_routeDetails == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteDetailsModalWidget(
        routeData: _routeDetails!,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _beginRoute() async {
    // Show trip type selector dialog
    final tripType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Trip Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.wb_sunny, color: AppTheme.primaryDriver),
              title: Text('Morning Pickup'),
              subtitle: Text('Pick up students from home'),
              onTap: () => Navigator.pop(context, 'pickup'),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: Icon(Icons.nights_stay, color: AppTheme.primaryDriver),
              title: Text('Afternoon Dropoff'),
              subtitle: Text('Drop off students at home'),
              onTap: () => Navigator.pop(context, 'dropoff'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    // User cancelled
    if (tripType == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend to start trip
      final response = await _apiService.startTrip(tripType: tripType);
      final trip = response['trip'];

      if (trip != null && trip['id'] != null) {
        // Save trip ID and state to SharedPreferences for persistence
        final prefs = await SharedPreferences.getInstance();

        // Ensure trip ID is an integer
        final tripId = trip['id'] is int ? trip['id'] : int.parse(trip['id'].toString());

        await prefs.setInt('current_trip_id', tripId);
        await prefs.setString('current_trip_type', trip['trip_type'] ?? tripType);
        await prefs.setString('trip_start_time', DateTime.now().toIso8601String());
        await prefs.setBool('trip_in_progress', true);

        // Start native background location service
        try {
          final accessToken = prefs.getString('access_token') ?? '';
          final busId = _busData?['id'];

          if (accessToken.isNotEmpty && busId != null) {
            final serviceStarted = await _nativeLocationService.startLocationTracking(
              token: accessToken,
              busId: busId is int ? busId : int.parse(busId.toString()),
              apiUrl: ApiConfig.apiBaseUrl,
            );

            if (!serviceStarted && mounted) {
              // Show warning but don't block trip start
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Warning: Background location tracking may not work'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          // Don't block trip start even if native service fails
        }

        setState(() {
          _isLoading = false;
        });

        HapticFeedback.heavyImpact();

        // Navigate to active trip screen
        if (mounted) {
          Navigator.pushNamed(context, '/driver-active-trip-screen');
        }
      } else {
        throw Exception('Failed to create trip - no trip ID returned');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start trip: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
            'Are you sure you want to logout? Any unsaved data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/shared-login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalAlert,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showResetTripStateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warningState),
            SizedBox(width: 2.w),
            Expanded(child: Text('Reset Trip State')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will clear your local trip state and stop all location tracking.',
              style: TextStyle(fontSize: 14),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Warning:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningState,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'If you have an active trip, make sure to end it properly from the Active Trip screen first. Only use this option if the app is stuck.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Clear the stale state
              await _clearStaleLocalTripState();

              // Refresh the screen
              setState(() {
                _hasActiveTrip = false;
                _activeTripInfo = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Trip state reset successfully'),
                  backgroundColor: AppTheme.successAction,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningState,
            ),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  bool get _canBeginRoute =>
      _isLocationEnabled &&
      _isGpsConnected &&
      _isChecklistComplete &&
      _driverData?['routeAssignment'] != 'Not Assigned Yet';

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryDriver.withValues(alpha: 0.05),
              AppTheme.backgroundPrimary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryDriver,
                      AppTheme.primaryDriver.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDriver.withValues(alpha: 0.3),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (_driverData?['driverName'] as String? ?? 'D')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDriver,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _driverData?['driverName'] as String? ?? 'Driver',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'ID: ${_driverData?['driverId'] as String? ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: 'home',
                      title: 'Start Shift',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: 'directions_bus',
                      title: 'Active Trip',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/driver-active-trip-screen');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: 'history',
                      title: 'Trip History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/driver-trip-history-screen');
                      },
                    ),
                    Divider(height: 3.h),
                    _buildDrawerItem(
                      context,
                      icon: 'person',
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Profile page coming soon')),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: 'settings',
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Settings page coming soon')),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: 'help',
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Help page coming soon')),
                        );
                      },
                    ),
                    if (_hasActiveTrip)
                      _buildDrawerItem(
                        context,
                        icon: 'refresh',
                        title: 'Reset Trip State',
                        onTap: () {
                          Navigator.pop(context);
                          _showResetTripStateDialog();
                        },
                      ),
                  ],
                ),
              ),

              // Logout button at bottom
              Container(
                padding: EdgeInsets.all(4.w),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.criticalAlert,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'logout',
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.primaryDriver.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomIconWidget(
          iconName: icon,
          color: AppTheme.primaryDriver,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        drawer: _buildDrawer(context),
        body: SafeArea(
          child: _isLoadingData
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 2.h),
                      Text('Loading driver information...'),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 2.h),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 2.h),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                            child: Text('Continue Anyway'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // GPS Status Bar
                        GpsStatusWidget(
                          isGpsConnected: _isGpsConnected,
                          currentTime: _currentTime,
                        ),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Driver Header
                                Builder(
                                  builder: (context) => DriverHeaderWidget(
                                    driverName: _driverData?['driverName'] as String? ?? 'Driver',
                                    driverId: _driverData?['driverId'] as String? ?? 'N/A',
                                    onLogout: _showLogoutConfirmation,
                                    onMenuTap: () => Scaffold.of(context).openDrawer(),
                                  ),
                                ),

                                // Not Assigned Info Banner
                                if (_driverData?['routeAssignment'] == 'Not Assigned Yet')
                                  Container(
                                    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                                    padding: EdgeInsets.all(4.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningState.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.warningState.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppTheme.warningState,
                                          size: 24,
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Not Assigned Yet',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.warningState,
                                                ),
                                              ),
                                              SizedBox(height: 0.5.h),
                                              Text(
                                                'You are not assigned to any bus yet. Please contact your administrator to get a bus assignment.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Route Assignment Card
                                RouteAssignmentCardWidget(
                                  routeName: _driverData?['routeAssignment'] as String? ?? 'No Assignment',
                                  estimatedDuration:
                                      _driverData?['estimatedDuration'] as String? ?? 'N/A',
                                  studentCount: _driverData?['studentCount'] as int? ?? 0,
                                  assignedChildren: _assignedChildren,
                                  busNumber: _driverData?['busNumber'] as String?,
                                  routeNameOnly: _driverData?['routeName'] as String?,
                                  onTap: _showRouteDetailsModal,
                                ),

                                // Location Services Toggle
                                LocationServicesWidget(
                                  isLocationEnabled: _isLocationEnabled,
                                  accuracyText: _accuracyText,
                                  onToggle: _toggleLocationServices,
                                ),

                                // Pre-Trip Checklist
                                PreTripChecklistWidget(
                                  checklistItems: _checklistItems,
                                  onChecklistComplete: _onChecklistComplete,
                                ),

                                SizedBox(height: 2.h),
                              ],
                            ),
                          ),
                        ),

                        // Begin Route Button
                        BeginRouteButtonWidget(
                          isEnabled: _canBeginRoute,
                          isLoading: _isLoading,
                          onPressed: _hasActiveTrip ? _continueTrip : _beginRoute,
                          onLongPress: _showRouteDetailsModal,
                          isContinueTrip: _hasActiveTrip,
                          tripDuration: _hasActiveTrip ? _formatTripDuration() : null,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
