import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_tab_bar.dart';
import './widgets/attendance_summary_widget.dart';
import './widgets/route_header_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/student_attendance_card.dart';

/// Busminder Attendance Screen for efficient student attendance tracking
/// with pickup/drop-off management using friendly, approachable interface design
class BusminderAttendanceScreen extends StatefulWidget {
  const BusminderAttendanceScreen({super.key});

  @override
  State<BusminderAttendanceScreen> createState() =>
      _BusminderAttendanceScreenState();
}

class _BusminderAttendanceScreenState extends State<BusminderAttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Search functionality
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredStudents = [];

  // Mock route information
  final Map<String, dynamic> _routeInfo = {
    "routeId": "RT001",
    "routeName": "Greenwood Elementary Route A",
    "status": "active",
    "startTime": "07:30 AM",
    "tripType": "Morning Pickup",
    "driverId": "DRV001",
    "driverName": "Michael Johnson",
    "busNumber": "BUS-042",
  };

  // Mock student data with comprehensive information
  final List<Map<String, dynamic>> _allStudents = [
    {
      "id": 1,
      "name": "Emma Thompson",
      "grade": "3rd",
      "photo":
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face",
      "status": "pending",
      "hasSpecialNeeds": false,
      "parentContact": "+1 (555) 123-4567",
      "emergencyContact": "+1 (555) 987-6543",
      "address": "123 Oak Street, Greenwood",
      "notes": "",
      "pickupTime": "07:45 AM",
      "dropoffTime": "03:15 PM",
    },
    {
      "id": 2,
      "name": "Liam Rodriguez",
      "grade": "4th",
      "photo":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "status": "picked_up",
      "hasSpecialNeeds": true,
      "parentContact": "+1 (555) 234-5678",
      "emergencyContact": "+1 (555) 876-5432",
      "address": "456 Pine Avenue, Greenwood",
      "notes": "Requires wheelchair assistance",
      "pickupTime": "07:50 AM",
      "dropoffTime": "03:20 PM",
    },
    {
      "id": 3,
      "name": "Sophia Chen",
      "grade": "2nd",
      "photo":
          "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
      "status": "dropped_off",
      "hasSpecialNeeds": false,
      "parentContact": "+1 (555) 345-6789",
      "emergencyContact": "+1 (555) 765-4321",
      "address": "789 Maple Drive, Greenwood",
      "notes": "",
      "pickupTime": "07:55 AM",
      "dropoffTime": "03:25 PM",
    },
    {
      "id": 4,
      "name": "Noah Williams",
      "grade": "5th",
      "photo":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "status": "pending",
      "hasSpecialNeeds": false,
      "parentContact": "+1 (555) 456-7890",
      "emergencyContact": "+1 (555) 654-3210",
      "address": "321 Elm Street, Greenwood",
      "notes": "",
      "pickupTime": "08:00 AM",
      "dropoffTime": "03:30 PM",
    },
    {
      "id": 5,
      "name": "Ava Johnson",
      "grade": "1st",
      "photo":
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      "status": "picked_up",
      "hasSpecialNeeds": true,
      "parentContact": "+1 (555) 567-8901",
      "emergencyContact": "+1 (555) 543-2109",
      "address": "654 Birch Lane, Greenwood",
      "notes": "Food allergies - peanuts",
      "pickupTime": "08:05 AM",
      "dropoffTime": "03:35 PM",
    },
    {
      "id": 6,
      "name": "Ethan Davis",
      "grade": "3rd",
      "photo":
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face",
      "status": "pending",
      "hasSpecialNeeds": false,
      "parentContact": "+1 (555) 678-9012",
      "emergencyContact": "+1 (555) 432-1098",
      "address": "987 Cedar Court, Greenwood",
      "notes": "",
      "pickupTime": "08:10 AM",
      "dropoffTime": "03:40 PM",
    },
    {
      "id": 7,
      "name": "Isabella Martinez",
      "grade": "4th",
      "photo":
          "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop&crop=face",
      "status": "dropped_off",
      "hasSpecialNeeds": false,
      "parentContact": "+1 (555) 789-0123",
      "emergencyContact": "+1 (555) 321-0987",
      "address": "147 Willow Way, Greenwood",
      "notes": "",
      "pickupTime": "08:15 AM",
      "dropoffTime": "03:45 PM",
    },
    {
      "id": 8,
      "name": "Mason Brown",
      "grade": "2nd",
      "photo":
          "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face",
      "status": "picked_up",
      "hasSpecialNeeds": false,
      "parentContact": "+1 (555) 890-1234",
      "emergencyContact": "+1 (555) 210-9876",
      "address": "258 Spruce Street, Greenwood",
      "notes": "",
      "pickupTime": "08:20 AM",
      "dropoffTime": "03:50 PM",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredStudents = List.from(_allStudents);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filter students based on search query
  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          final name = (student['name'] as String).toLowerCase();
          final grade = (student['grade'] as String).toLowerCase();
          return name.contains(_searchQuery) || grade.contains(_searchQuery);
        }).toList();
      }
    });
  }

  // Handle student status changes
  void _handleStatusChange(String studentId, String newStatus) {
    setState(() {
      final studentIndex = _allStudents.indexWhere(
        (student) => student['id'].toString() == studentId,
      );
      if (studentIndex != -1) {
        _allStudents[studentIndex]['status'] = newStatus;
        // Update filtered list as well
        final filteredIndex = _filteredStudents.indexWhere(
          (student) => student['id'].toString() == studentId,
        );
        if (filteredIndex != -1) {
          _filteredStudents[filteredIndex]['status'] = newStatus;
        }
      }
    });

    // Show confirmation toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Student status updated to ${newStatus.replaceAll('_', ' ')}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Handle swipe right - add note
  void _handleSwipeRight(String studentId) {
    _showAddNoteDialog(studentId);
  }

  // Handle swipe left - show contact info
  void _handleSwipeLeft(String studentId) {
    _showContactInfoDialog(studentId);
  }

  // Handle long press - show context menu
  void _handleLongPress(String studentId) {
    _showStudentContextMenu(studentId);
  }

  // Show add note dialog
  void _showAddNoteDialog(String studentId) {
    final student = _allStudents.firstWhere(
      (s) => s['id'].toString() == studentId,
      orElse: () => {},
    );

    if (student.isEmpty) return;

    final TextEditingController noteController = TextEditingController();
    noteController.text = student['notes'] as String? ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note - ${student['name']}'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter note for this student...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                student['notes'] = noteController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note saved successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show contact info dialog
  void _showContactInfoDialog(String studentId) {
    final student = _allStudents.firstWhere(
      (s) => s['id'].toString() == studentId,
      orElse: () => {},
    );

    if (student.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Info - ${student['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactRow('Parent', student['parentContact'] as String),
            const SizedBox(height: 8),
            _buildContactRow(
                'Emergency', student['emergencyContact'] as String),
            const SizedBox(height: 8),
            _buildContactRow('Address', student['address'] as String),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  // Show student context menu
  void _showStudentContextMenu(String studentId) {
    final student = _allStudents.firstWhere(
      (s) => s['id'].toString() == studentId,
      orElse: () => {},
    );

    if (student.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              student['name'] as String,
              style: AppTheme.lightBusminderTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (student['hasSpecialNeeds'] == true) ...[
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: const Text('Special Needs Information'),
                subtitle: Text(
                    student['notes'] as String? ?? 'No additional information'),
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Pickup Time'),
              subtitle: Text(student['pickupTime'] as String),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Drop-off Time'),
              subtitle: Text(student['dropoffTime'] as String),
            ),
          ],
        ),
      ),
    );
  }

  // Pull to refresh functionality
  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      // Refresh data - in real app, this would fetch from API
      _filteredStudents = List.from(_allStudents);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance data refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Show add student modal
  void _showAddStudentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        height: 60.h,
        child: Column(
          children: [
            Text(
              'Add Student to Route',
              style: AppTheme.lightBusminderTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Student Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Grade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Parent Contact',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Student added to route'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Add Student'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Calculate attendance statistics
  int get _totalStudents => _allStudents.length;
  int get _pickedUpCount =>
      _allStudents.where((s) => s['status'] == 'picked_up').length;
  int get _droppedOffCount =>
      _allStudents.where((s) => s['status'] == 'dropped_off').length;
  int get _pendingCount =>
      _allStudents.where((s) => s['status'] == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightBusminderTheme,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Attendance Tracking',
          subtitle: 'Manage student pickup & drop-off',
          actions: [
            IconButton(
              onPressed: () {
                // Navigate to settings or help
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings feature coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: CustomIconWidget(
                iconName: 'settings',
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
            currentIndex: 0, // Attendance tab is active
            onTap: (index) {
              if (index == 1) {
                // Navigate to Trip Progress screen
                Navigator.pushNamed(context, '/busminder-trip-progress-screen');
              }
            },
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Attendance Tab Content
            RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                slivers: [
                  // Route Header
                  SliverToBoxAdapter(
                    child: RouteHeaderWidget(
                      routeInfo: _routeInfo,
                      totalStudents: _totalStudents,
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: SearchBarWidget(
                      onSearchChanged: _filterStudents,
                    ),
                  ),

                  // Students List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _filteredStudents.length) return null;

                        final student = _filteredStudents[index];
                        return StudentAttendanceCard(
                          student: student,
                          onStatusChanged: _handleStatusChange,
                          onSwipeRight: _handleSwipeRight,
                          onSwipeLeft: _handleSwipeLeft,
                          onLongPress: _handleLongPress,
                        );
                      },
                      childCount: _filteredStudents.length,
                    ),
                  ),

                  // Attendance Summary
                  SliverToBoxAdapter(
                    child: AttendanceSummaryWidget(
                      totalStudents: _totalStudents,
                      pickedUpCount: _pickedUpCount,
                      droppedOffCount: _droppedOffCount,
                      pendingCount: _pendingCount,
                    ),
                  ),

                  // Bottom spacing
                  SliverToBoxAdapter(
                    child: SizedBox(height: 10.h),
                  ),
                ],
              ),
            ),

            // Trip Progress Tab Content (placeholder)
            const Center(
              child: Text(
                  'Trip Progress content will be loaded from separate screen'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddStudentModal,
          backgroundColor: AppTheme.primaryBusminder,
          foregroundColor: AppTheme.textOnPrimary,
          icon: CustomIconWidget(
            iconName: 'person_add',
            color: AppTheme.textOnPrimary,
            size: 24,
          ),
          label: const Text('Add Student'),
        ),
      ),
    );
  }
}

