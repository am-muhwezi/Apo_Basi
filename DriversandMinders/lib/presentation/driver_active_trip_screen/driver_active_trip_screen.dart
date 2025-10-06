import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/route_map_widget.dart';
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

  // Trip data
  DateTime _tripStartTime = DateTime.now().subtract(Duration(minutes: 45));
  String _elapsedTime = "00:45:32";
  String _currentStop = "Maple Street & 5th Avenue";

  // Mock trip data
  final Map<String, dynamic> _tripData = {
    "tripId": "TRP_20251003_001",
    "routeNumber": "101",
    "routeName": "Downtown Elementary Route",
    "driverName": "Michael Rodriguez",
    "busNumber": "BUS-047",
    "startTime": "07:30 AM",
    "estimatedEndTime": "08:45 AM",
    "totalDistance": "12.5 miles",
    "stops": [
      {
        "id": 1,
        "name": "Maple Street & 5th Avenue",
        "latitude": 40.7589,
        "longitude": -73.9851,
        "estimatedTime": "07:35 AM",
        "isCompleted": false,
        "studentsCount": 3,
      },
      {
        "id": 2,
        "name": "Oak Park Elementary",
        "latitude": 40.7614,
        "longitude": -73.9776,
        "estimatedTime": "07:42 AM",
        "isCompleted": false,
        "studentsCount": 5,
      },
      {
        "id": 3,
        "name": "Pine Ridge Community Center",
        "latitude": 40.7505,
        "longitude": -73.9934,
        "estimatedTime": "07:50 AM",
        "isCompleted": false,
        "studentsCount": 4,
      },
      {
        "id": 4,
        "name": "Sunset Boulevard School",
        "latitude": 40.7282,
        "longitude": -74.0776,
        "estimatedTime": "08:00 AM",
        "isCompleted": false,
        "studentsCount": 6,
      },
    ],
  };

  // Mock student data
  List<Map<String, dynamic>> _students = [
    {
      "id": 1,
      "name": "Emma Johnson",
      "grade": "3rd",
      "stopName": "Maple Street & 5th Avenue",
      "parentContact": "(555) 123-4567",
      "specialNotes": "Requires assistance boarding",
      "isPickedUp": false,
    },
    {
      "id": 2,
      "name": "Liam Chen",
      "grade": "2nd",
      "stopName": "Maple Street & 5th Avenue",
      "parentContact": "(555) 234-5678",
      "specialNotes": "",
      "isPickedUp": true,
    },
    {
      "id": 3,
      "name": "Sophia Martinez",
      "grade": "4th",
      "stopName": "Maple Street & 5th Avenue",
      "parentContact": "(555) 345-6789",
      "specialNotes": "Medication reminder at 9 AM",
      "isPickedUp": false,
    },
    {
      "id": 4,
      "name": "Noah Williams",
      "grade": "1st",
      "stopName": "Oak Park Elementary",
      "parentContact": "(555) 456-7890",
      "specialNotes": "",
      "isPickedUp": false,
    },
    {
      "id": 5,
      "name": "Ava Brown",
      "grade": "3rd",
      "stopName": "Oak Park Elementary",
      "parentContact": "(555) 567-8901",
      "specialNotes": "Early pickup required",
      "isPickedUp": false,
    },
    {
      "id": 6,
      "name": "Oliver Davis",
      "grade": "2nd",
      "stopName": "Pine Ridge Community Center",
      "parentContact": "(555) 678-9012",
      "specialNotes": "",
      "isPickedUp": false,
    },
    {
      "id": 7,
      "name": "Isabella Wilson",
      "grade": "4th",
      "stopName": "Pine Ridge Community Center",
      "parentContact": "(555) 789-0123",
      "specialNotes": "Allergic to peanuts",
      "isPickedUp": false,
    },
    {
      "id": 8,
      "name": "Ethan Garcia",
      "grade": "1st",
      "stopName": "Sunset Boulevard School",
      "parentContact": "(555) 890-1234",
      "specialNotes": "",
      "isPickedUp": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startElapsedTimeTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
  int get _remainingStops => (_tripData["stops"] as List)
      .where((s) => !(s["isCompleted"] as bool? ?? false))
      .length;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: CustomAppBar(
          title: 'Active Trip',
          subtitle: 'Route ${_tripData["routeNumber"]}',
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await Future.delayed(Duration(seconds: 1));
              setState(() {
                // Refresh trip data
              });
            },
            color: AppTheme.primaryDriver,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip status header
                  TripStatusHeaderWidget(
                    tripData: _tripData,
                    elapsedTime: _elapsedTime,
                    currentStop: _currentStop,
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
                    estimatedArrival: "08:45 AM",
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
