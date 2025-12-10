import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_tab_bar.dart';
import '../../widgets/busminder_drawer_widget.dart';
import '../busminder_trip_history_screen/busminder_trip_history_screen.dart';
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
  bool _isRefreshing = false;
  final ApiService _apiService = ApiService();

  int? _busId;
  String? _tripType;
  List<Map<String, dynamic>> _allStudents = [];

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
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _tripType = prefs.getString('current_trip_type');
      _busId = prefs.getInt('current_bus_id');

      if (_busId != null) {
        // Fetch children for this bus
        final childrenData = await _apiService.getBusChildren(_busId!);
        setState(() {
          _allStudents = childrenData.map((child) {
            return {
              'id': child['id'],
              'name': '${child['first_name']} ${child['last_name']}',
              'status': child['attendance_status'] ?? 'pending',
            };
          }).toList();

          // Calculate real statistics
          int totalStudents = _allStudents.length;
          int pickedUp = _allStudents.where((s) => s['status'] == 'picked_up').length;
          int droppedOff = _allStudents.where((s) => s['status'] == 'dropped_off').length;
          int absent = _allStudents.where((s) => s['status'] == 'absent').length;
          int completed = (_tripType == 'pickup' ? pickedUp : droppedOff) + absent;

          _statisticsData['totalStudents'] = totalStudents;
          _statisticsData['attendanceRate'] = totalStudents > 0
            ? double.parse(((completed / totalStudents) * 100).toStringAsFixed(1))
            : 0.0;
        });
      }
    } catch (e) {
      print('Error loading trip data: $e');
    }
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

  void _handleCompleteTripConfirmation() {
    _showConfirmationDialog(
      'Complete Trip',
      'Are you sure you want to complete this trip? This will end your shift.',
      () => _handleCompleteTrip(),
    );
  }

  Future<void> _handleCompleteTrip() async {
    try {
      // Calculate attendance summary
      int totalStudents = _allStudents.length;
      int pickedUp = _allStudents.where((s) => s['status'] == 'picked_up').length;
      int droppedOff = _allStudents.where((s) => s['status'] == 'dropped_off').length;
      int absent = _allStudents.where((s) => s['status'] == 'absent').length;
      int pending = _allStudents.where((s) => s['status'] == 'pending').length;

      int completed = _tripType == 'pickup' ? pickedUp : droppedOff;

      // Get trip ID from SharedPreferences (if stored) or use a default value
      final prefs = await SharedPreferences.getInstance();
      final tripId = prefs.getInt('current_trip_id');

      // Only call completeTrip API if we have a valid trip ID
      if (tripId != null) {
        await _apiService.completeTrip(
          tripId: tripId,
          totalStudents: totalStudents,
          studentsCompleted: completed,
          studentsAbsent: absent,
          studentsPending: pending,
        );
      }

      // Clear trip data from preferences
      await prefs.remove('current_trip_type');
      await prefs.remove('current_bus_id');
      await prefs.remove('current_trip_id');

      _showToast('Trip completed successfully!');

      // Navigate to trip summary/history screen with arguments
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const BusMinderTripHistoryScreen(),
            settings: RouteSettings(
              arguments: {
                'showSummary': true,
                'tripSummary': {
                  'totalStudents': totalStudents,
                  'studentsCompleted': completed,
                  'studentsAbsent': absent,
                  'studentsPending': pending,
                  'tripType': _tripType,
                  'busId': _busId,
                }
              },
            ),
          ),
          (route) => false,
        );
      });
    } catch (e) {
      print('Error completing trip: $e');
      _showToast('Error completing trip. Please try again.');
    }
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryBusminder.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBusminder,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: AppTheme.lightBusminderTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.lightBusminderTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightBusminderTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        drawer: BusminderDrawerWidget(
          currentRoute: '/busminder-trip-progress-screen',
        ),
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
            controller: _tabController,
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
                // Use pushReplacementNamed to avoid stack buildup
                Navigator.pushReplacementNamed(context, '/busminder-attendance-screen');
              }
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryBusminder,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),

                  // Trip Info Card
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_bus, color: AppTheme.primaryBusminder, size: 24),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _tripType == 'pickup' ? 'Morning Pickup Trip' : 'Afternoon Dropoff Trip',
                                style: AppTheme.lightBusminderTheme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: AppTheme.successAction.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: AppTheme.successAction,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Divider(),
                        SizedBox(height: 2.h),
                        Text(
                          'Trip Summary',
                          style: AppTheme.lightBusminderTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        _buildSummaryRow('Total Students', '${_statisticsData['totalStudents']}', Icons.people),
                        _buildSummaryRow('Completed', '${_allStudents.where((s) => s['status'] == (_tripType == 'pickup' ? 'picked_up' : 'dropped_off')).length}', Icons.check_circle),
                        _buildSummaryRow('Absent', '${_allStudents.where((s) => s['status'] == 'absent').length}', Icons.person_off),
                        _buildSummaryRow('Pending', '${_allStudents.where((s) => s['status'] == 'pending').length}', Icons.schedule),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Complete Trip Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleCompleteTripConfirmation,
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
                          Icon(Icons.check_circle, color: Colors.white, size: 24),
                          SizedBox(width: 2.w),
                          Text(
                            'Complete Trip & End Shift',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}
