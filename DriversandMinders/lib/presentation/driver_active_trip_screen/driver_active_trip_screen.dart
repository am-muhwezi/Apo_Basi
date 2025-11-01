import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/route_map_widget.dart';
import './widgets/socket_status_widget.dart';
import './widgets/student_list_widget.dart';
import './widgets/trip_statistics_widget.dart';
import './widgets/trip_status_header_widget.dart';

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
  final SocketService _socketService = SocketService();

  // Trip data
  DateTime _tripStartTime = DateTime.now();
  String _elapsedTime = "00:00:00";
  String _currentStop = "";
  bool _isLoadingData = true;
  String? _errorMessage;

  // Real trip data from API
  Map<String, dynamic> _tripData = {};
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _routeDetails;
  Map<String, dynamic>? _busData;

  // Socket.IO connection status
  bool _isSocketConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTripData();
    _startElapsedTimeTimer();
  }

  Future<void> _loadTripData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // Get user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
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

      // Extract route data
      _routeDetails = routeResponse;

      // Build trip data object
      _tripData = {
        "tripId": "TRP_${DateTime.now().toString().substring(0, 10).replaceAll('-', '')}_${_busData?['id'] ?? '001'}",
        "routeNumber": routeResponse['route_name']?.toString() ?? "N/A",
        "routeName": routeResponse['route_name'] ?? 'No Route',
        "driverName": userName,
        "busNumber": _busData?['bus_number'] ?? 'N/A',
        "startTime": "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        "estimatedEndTime": routeResponse['estimated_duration'] ?? 'N/A',
        "totalDistance": routeResponse['total_distance']?.toString() ?? 'N/A',
        "stops": [], // Populate from route if available
      };

      // Extract and convert children data to students list
      if (routeResponse['children'] != null && routeResponse['children'] is List) {
        _students = [];
        for (var child in routeResponse['children']) {
          _students.add({
            "id": child['id'] ?? 0,
            "name": '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
            "grade": child['grade']?.toString() ?? child['class_grade']?.toString() ?? 'N/A',
            "stopName": child['address']?.toString() ?? 'No address',
            "parentContact": child['emergency_contact']?.toString() ?? child['parent_contact']?.toString() ?? 'N/A',
            "specialNotes": child['special_needs']?.toString() ?? '',
            "isPickedUp": false,
          });
        }

        // Set current stop to first student's address if available
        if (_students.isNotEmpty) {
          _currentStop = _students[0]['stopName'] ?? '';
        }
      }

      setState(() {
        _isLoadingData = false;
      });

      // Initialize Socket.IO connection after data is loaded
      _initializeSocketConnection();
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
          "startTime": "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
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
    _socketService.disconnect();
    super.dispose();
  }

  /// Initialize Socket.IO connection and start location tracking
  Future<void> _initializeSocketConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null || _busData == null) {
        print('⚠️ Cannot initialize socket: Missing user ID or bus data');
        return;
      }

      final busId = _busData!['id']?.toString() ?? _busData!['bus_number']?.toString() ?? 'unknown';

      // Initialize socket connection
      _socketService.initializeSocket(
        serverUrl: 'http://192.168.100.43:4000', // TODO: Move to config
        driverId: userId,
        busId: busId,
      );

      // Wait a moment for connection to establish
      await Future.delayed(Duration(seconds: 2));

      // Check connection status
      setState(() {
        _isSocketConnected = _socketService.isConnected;
      });

      if (_socketService.isConnected) {
        // Start location tracking and emission
        _socketService.startLocationTracking();
        print('✅ Socket.IO: Connected and tracking location');
      } else {
        print('⚠️ Socket.IO: Failed to connect');
      }
    } catch (e) {
      print('❌ Socket.IO initialization error: $e');
      setState(() {
        _isSocketConnected = false;
      });
    }
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

  void _onPickupStatusChanged(int index, bool isPickedUp) {
    setState(() {
      _students[index]["isPickedUp"] = isPickedUp;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPickedUp
              ? '${_students[index]["name"]} marked as picked up'
              : '${_students[index]["name"]} marked as not picked up',
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onFullScreenMapTap() {
    // Navigate to full screen map view
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Route Map'),
            backgroundColor: AppTheme.primaryDriver,
            foregroundColor: AppTheme.textOnPrimary,
          ),
          body: RouteMapWidget(
            tripData: _tripData,
            onFullScreenTap: () => Navigator.pop(context),
          ),
        ),
      ),
    );
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

  void _endTrip() {
    HapticFeedback.mediumImpact();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip ended successfully'),
        backgroundColor: AppTheme.successAction,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to trip history
    Navigator.pushReplacementNamed(context, '/driver-trip-history-screen');
  }

  void _showSocketInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: _isSocketConnected ? 'wifi' : 'wifi_off',
              color: _isSocketConnected ? AppTheme.successAction : AppTheme.criticalAlert,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Live Tracking Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection: ${_isSocketConnected ? "Connected" : "Disconnected"}',
              style: TextStyle(
                color: _isSocketConnected ? AppTheme.successAction : AppTheme.criticalAlert,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _isSocketConnected
                  ? 'Your location is being shared in real-time with parents. They can see your bus location on their map.'
                  : 'Unable to connect to the live tracking server. Your location is not being shared with parents in real-time.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            if (_socketService.isConnected) ...[
              SizedBox(height: 2.h),
              Divider(),
              SizedBox(height: 1.h),
              Text(
                'Technical Info:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Socket ID: ${_socketService.socketId ?? "N/A"}\n'
                'Bus ID: ${_socketService.currentBusId ?? "N/A"}\n'
                'Server: http://192.168.100.43:4000',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.sp,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isSocketConnected)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initializeSocketConnection();
              },
              child: Text('Retry Connection'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onEmergencyPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.criticalAlert,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Emergency Contacts'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'local_police',
                color: AppTheme.criticalAlert,
                size: 20,
              ),
              title: Text('Emergency Services'),
              subtitle: Text('911'),
              onTap: () {
                // Handle emergency call
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'support_agent',
                color: AppTheme.primaryDriver,
                size: 20,
              ),
              title: Text('Dispatch Support'),
              subtitle: Text('(555) 999-0000'),
              onTap: () {
                // Handle support call
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  int get _studentsPickedUp =>
      _students.where((s) => s["isPickedUp"] as bool? ?? false).length;
  int get _remainingStops => _tripData["stops"] != null
      ? (_tripData["stops"] as List).where((s) => !(s["isCompleted"] as bool? ?? false)).length
      : _students.length - _studentsPickedUp;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: CustomAppBar(
          title: 'Active Trip',
          subtitle: 'Route ${_tripData["routeNumber"] ?? "N/A"}',
          actions: [
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/driver-trip-history-screen'),
              icon: CustomIconWidget(
                iconName: 'history',
                color: AppTheme.textOnPrimary,
                size: 24,
              ),
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
                                    style: TextStyle(color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Trip status header
                        TripStatusHeaderWidget(
                          tripData: _tripData,
                          elapsedTime: _elapsedTime,
                          currentStop: _currentStop.isEmpty ? 'Starting route...' : _currentStop,
                        ),

                        SizedBox(height: 2.h),

                        // Socket.IO connection status
                        SocketStatusWidget(
                          isConnected: _isSocketConnected,
                          onTap: () {
                            _showSocketInfoDialog();
                          },
                        ),

                        SizedBox(height: 2.h),

                        // Route map
                        RouteMapWidget(
                          tripData: _tripData,
                          onFullScreenTap: _onFullScreenMapTap,
                        ),

                        SizedBox(height: 2.h),

                        // Trip statistics
                        TripStatisticsWidget(
                          studentsPickedUp: _studentsPickedUp,
                          totalStudents: _students.length,
                          remainingStops: _remainingStops,
                          estimatedArrival: _tripData["estimatedEndTime"]?.toString() ?? "N/A",
                        ),

                        SizedBox(height: 2.h),

                        // Student list
                        StudentListWidget(
                          students: _students,
                          onPickupStatusChanged: _onPickupStatusChanged,
                        ),

                        SizedBox(height: 10.h), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onEmergencyPressed,
          backgroundColor: AppTheme.criticalAlert,
          child: CustomIconWidget(
            iconName: 'emergency',
            color: AppTheme.textOnPrimary,
            size: 24,
          ),
        ),
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
