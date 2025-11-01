import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import './widgets/begin_route_button_widget.dart';
import './widgets/driver_header_widget.dart';
import './widgets/gps_status_widget.dart';
import './widgets/location_services_widget.dart';
import './widgets/pre_trip_checklist_widget.dart';
import './widgets/route_assignment_card_widget.dart';
import './widgets/route_details_modal_widget.dart';

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

  // Driver data fetched from API
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _busData;
  Map<String, dynamic>? _routeDetails;
  List<Map<String, dynamic>> _assignedChildren = [];
  String? _errorMessage;

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
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // Get user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Driver';
      final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

      // Try to get driver's bus information from API
      try {
        final busResponse = await _apiService.getDriverBus();
        print('Bus Response: $busResponse');

        // Get driver's route information from API
        final routeResponse = await _apiService.getDriverRoute();
        print('Route Response: $routeResponse');

        // Extract bus data
        _busData = busResponse['buses'] is Map
            ? busResponse['buses'] as Map<String, dynamic>
            : (busResponse['buses'] is List &&
                    (busResponse['buses'] as List).isNotEmpty
                ? busResponse['buses'][0] as Map<String, dynamic>
                : null);

        // Extract route data
        _routeDetails = routeResponse;

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
        setState(() {
          _errorMessage =
              'Could not connect to server. Using offline mode.\n${apiError.toString()}';
        });
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
        "routeAssignment": "No Assignment",
        "estimatedDuration": "N/A",
        "studentCount": 0,
      };

      _routeDetails = {
        "routeName": "No Route Assigned",
        "totalDistance": "N/A",
        "estimatedTime": "N/A",
        "totalStops": 0,
        "totalStudents": 0,
        "keyStops": [],
      };
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
    setState(() {
      _isLoading = true;
    });

    // Simulate route initialization
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    HapticFeedback.heavyImpact();

    // Navigate to active trip screen
    Navigator.pushNamed(context, '/driver-active-trip-screen');
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

  bool get _canBeginRoute =>
      _isLocationEnabled && _isGpsConnected && _isChecklistComplete;

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
                          onPressed: _beginRoute,
                          onLongPress: _showRouteDetailsModal,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
