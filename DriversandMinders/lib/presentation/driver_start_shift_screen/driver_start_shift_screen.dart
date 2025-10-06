import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  String _currentTime = '';
  String _accuracyText = 'Searching...';
  Timer? _timeTimer;
  StreamSubscription<Position>? _positionStream;

  // Mock data
  final Map<String, dynamic> _driverData = {
    "driverId": "DRV001",
    "driverName": "Michael Rodriguez",
    "routeAssignment": "Route A - Downtown Elementary",
    "estimatedDuration": "45 minutes",
    "studentCount": 28,
  };

  final Map<String, dynamic> _routeDetails = {
    "routeName": "Route A - Downtown Elementary",
    "totalDistance": "12.5 miles",
    "estimatedTime": "45 minutes",
    "totalStops": 8,
    "totalStudents": 28,
    "morningPickup": 28,
    "afternoonDrop": 28,
    "mapPreview":
        "https://images.unsplash.com/photo-1524661135-423995f22d0b?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    "keyStops": [
      {
        "name": "Maple Street & 5th Avenue",
        "studentCount": 4,
        "estimatedTime": "7:15 AM"
      },
      {
        "name": "Downtown Elementary School",
        "studentCount": 28,
        "estimatedTime": "7:45 AM"
      },
      {
        "name": "Pine Ridge Community Center",
        "studentCount": 6,
        "estimatedTime": "8:00 AM"
      },
    ]
  };

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteDetailsModalWidget(
        routeData: _routeDetails,
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: SafeArea(
          child: Column(
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
                      DriverHeaderWidget(
                        driverName: _driverData['driverName'] as String,
                        driverId: _driverData['driverId'] as String,
                        onLogout: _showLogoutConfirmation,
                      ),

                      // Route Assignment Card
                      RouteAssignmentCardWidget(
                        routeName: _driverData['routeAssignment'] as String,
                        estimatedDuration:
                            _driverData['estimatedDuration'] as String,
                        studentCount: _driverData['studentCount'] as int,
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
