import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_tab_bar.dart';
import './widgets/current_stop_card_widget.dart';
import './widgets/progress_bar_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/route_map_widget.dart';
import './widgets/trip_statistics_widget.dart';
import './widgets/trip_timeline_widget.dart';

class BusminderTripProgressScreen extends StatefulWidget {
  const BusminderTripProgressScreen({super.key});

  @override
  State<BusminderTripProgressScreen> createState() =>
      _BusminderTripProgressScreenState();
}

class _BusminderTripProgressScreenState
    extends State<BusminderTripProgressScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomIndex = 1;
  bool _isRefreshing = false;

  // Mock data for trip progress
  final Map<String, dynamic> _tripData = {
    "tripId": "TRIP_001",
    "routeName": "Route 15 - Morning",
    "currentStop": "Maple Street Elementary",
    "nextStop": "Oak Avenue School",
    "estimatedArrival": "08:45 AM",
    "progressPercentage": 65.0,
    "startTime": "07:30 AM",
    "driverName": "John Smith",
    "busNumber": "BUS-015",
  };

  final Map<String, dynamic> _locationData = {
    "latitude": 40.7589,
    "longitude": -73.9851,
    "speed": 25.5,
    "heading": 180.0,
    "lastUpdate": "2025-10-03 21:19:53",
  };

  final List<Map<String, dynamic>> _milestones = [
    {
      "name": "Central Park Stop",
      "position": 25.0,
      "completed": true,
      "studentCount": 8,
    },
    {
      "name": "Maple Street Elementary",
      "position": 65.0,
      "completed": true,
      "studentCount": 12,
    },
    {
      "name": "Oak Avenue School",
      "position": 85.0,
      "completed": false,
      "studentCount": 6,
    },
    {
      "name": "Final Destination",
      "position": 100.0,
      "completed": false,
      "studentCount": 0,
    },
  ];

  final List<Map<String, dynamic>> _routeStops = [
    {
      "name": "Central Park Stop",
      "latitude": 40.7589,
      "longitude": -73.9851,
      "completed": true,
      "studentCount": 8,
    },
    {
      "name": "Maple Street Elementary",
      "latitude": 40.7614,
      "longitude": -73.9776,
      "completed": true,
      "studentCount": 12,
    },
    {
      "name": "Oak Avenue School",
      "latitude": 40.7505,
      "longitude": -73.9934,
      "completed": false,
      "studentCount": 6,
    },
  ];

  final Map<String, dynamic> _currentStopData = {
    "name": "Maple Street Elementary",
    "instructions": "Please wait for all students to board before proceeding",
    "students": [
      {
        "id": "STU_001",
        "name": "Emma Johnson",
        "grade": "3rd",
        "isBoarding": true,
        "status": "boarded",
      },
      {
        "id": "STU_002",
        "name": "Michael Chen",
        "grade": "4th",
        "isBoarding": true,
        "status": "waiting",
      },
      {
        "id": "STU_003",
        "name": "Sofia Rodriguez",
        "grade": "3rd",
        "isBoarding": true,
        "status": "waiting",
      },
      {
        "id": "STU_004",
        "name": "David Thompson",
        "grade": "5th",
        "isBoarding": true,
        "status": "absent",
      },
    ],
  };

  final Map<String, dynamic> _statisticsData = {
    "totalStudents": 26,
    "attendanceRate": 88.5,
    "onTimePerformance": 92.0,
    "completedStops": 2,
    "totalStops": 4,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Update mock data to simulate real-time updates
    setState(() {
      _locationData['lastUpdate'] = DateTime.now().toString();
      _isRefreshing = false;
    });

    _showToast('Trip data updated');
  }

  void _handleAttendanceToggle(String studentId, bool isBoarding) {
    setState(() {
      final students =
          (_currentStopData['students'] as List).cast<Map<String, dynamic>>();
      final studentIndex =
          students.indexWhere((student) => student['id'] == studentId);

      if (studentIndex != -1) {
        students[studentIndex]['status'] = isBoarding ? 'boarded' : 'absent';

        // Update statistics
        final currentAttendance = _statisticsData['attendanceRate'] as double;
        _statisticsData['attendanceRate'] = isBoarding
            ? (currentAttendance + 2.0).clamp(0.0, 100.0)
            : (currentAttendance - 2.0).clamp(0.0, 100.0);
      }
    });

    _showToast(
        isBoarding ? 'Student marked as boarded' : 'Student marked as absent');
  }

  void _handleEmergencyContact() {
    HapticFeedback.heavyImpact();
    _showToast('Emergency services contacted');
  }

  void _handleDriverCommunication() {
    _showToast('Connecting to driver...');
  }

  void _handleParentNotification() {
    _showToast('Parent notifications sent');
  }

  void _handleMarkStopComplete() {
    final students =
        (_currentStopData['students'] as List).cast<Map<String, dynamic>>();
    final waitingStudents =
        students.where((student) => student['status'] == 'waiting').length;

    if (waitingStudents > 0) {
      _showConfirmationDialog(
        'Incomplete Attendance',
        'There are $waitingStudents students still waiting. Mark stop as complete anyway?',
        () => _completeStop(),
      );
    } else {
      _completeStop();
    }
  }

  void _completeStop() {
    setState(() {
      // Update progress
      _tripData['progressPercentage'] = 85.0;
      _tripData['currentStop'] = 'Oak Avenue School';
      _tripData['nextStop'] = 'Final Destination';
      _tripData['estimatedArrival'] = '09:15 AM';

      // Update milestones
      final currentMilestone = _milestones.firstWhere(
        (milestone) => milestone['name'] == 'Oak Avenue School',
      );
      currentMilestone['completed'] = true;

      // Update statistics
      _statisticsData['completedStops'] = 3;
    });

    _showToast('Stop marked as complete');
  }

  void _showConfirmationDialog(
      String title, String message, VoidCallback onConfirm) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBusminder,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Confirm',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.primaryBusminder,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightBusminderTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: CustomAppBar(
          title: 'Trip Progress',
          subtitle: _tripData['routeName'] as String,
          actions: [
            IconButton(
              onPressed: _handleRefresh,
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.textOnPrimary,
                        ),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'refresh',
                      color: AppTheme.textOnPrimary,
                      size: 24,
                    ),
            ),
          ],
          bottom: CustomTabBar(
            tabs: const [
              CustomTab(
                text: 'Attendance',
                icon: Icons.how_to_reg,
              ),
              CustomTab(
                text: 'Progress',
                icon: Icons.route,
              ),
            ],
            currentIndex: 1, // Progress tab is active
            onTap: (index) {
              if (index == 0) {
                Navigator.pushNamed(context, '/busminder-attendance-screen');
              }
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryBusminder,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 1.h),
                TripTimelineWidget(tripData: _tripData),
                ProgressBarWidget(
                  progressPercentage: _tripData['progressPercentage'] as double,
                  milestones: _milestones,
                ),
                RouteMapWidget(
                  locationData: _locationData,
                  stops: _routeStops,
                ),
                CurrentStopCardWidget(
                  stopData: _currentStopData,
                  onAttendanceToggle: _handleAttendanceToggle,
                ),
                TripStatisticsWidget(statisticsData: _statisticsData),
                QuickActionsWidget(
                  onEmergencyContact: _handleEmergencyContact,
                  onDriverCommunication: _handleDriverCommunication,
                  onParentNotification: _handleParentNotification,
                ),
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ElevatedButton(
                    onPressed: _handleMarkStopComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successAction,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Mark Stop Complete',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomBar(
          currentIndex: _currentBottomIndex,
          onTap: (index) {
            setState(() {
              _currentBottomIndex = index;
            });

            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/busminder-attendance-screen');
                break;
              case 1:
                // Current screen - do nothing
                break;
            }
          },
        ),
      ),
    );
  }
}
