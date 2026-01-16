import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/busminder_drawer_widget.dart';
import '../busminder_trip_history_screen/busminder_trip_history_screen.dart';

/// Unified Busminder Active Trip Screen
/// Shows children list with attendance actions and end shift button
class BusminderActiveTripScreen extends StatefulWidget {
  const BusminderActiveTripScreen({super.key});

  @override
  State<BusminderActiveTripScreen> createState() =>
      _BusminderActiveTripScreenState();
}

class _BusminderActiveTripScreenState extends State<BusminderActiveTripScreen> {
  final ApiService _apiService = ApiService();

  // Loading states
  bool _isLoading = true;
  bool _isEndingShift = false;
  String? _errorMessage;

  // Trip information
  int? _busId;
  String? _tripType;
  String? _tripStartTime;
  String? _busNumber;
  String? _userName;

  // Student data
  List<Map<String, dynamic>> _students = [];
  String _searchQuery = '';
  String? _tripDuration;
  Timer? _tripTimer;

  @override
  void initState() {
    super.initState();
    _checkActiveTrip();
  }

  void _startTripTimer(DateTime startTime) {
    _tripTimer?.cancel();

    void update() {
      final now = DateTime.now();
      final diff = now.difference(startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      final seconds = diff.inSeconds.remainder(60);

      final buffer = StringBuffer();
      if (hours > 0) {
        buffer.write(hours.toString().padLeft(2, '0'));
        buffer.write(':');
      }
      buffer.write(minutes.toString().padLeft(2, '0'));
      buffer.write(':');
      buffer.write(seconds.toString().padLeft(2, '0'));

      setState(() {
        _tripDuration = buffer.toString();
      });
    }

    update();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  Future<void> _checkActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final busId = prefs.getInt('current_bus_id');
    final tripType = prefs.getString('current_trip_type');

    if (busId == null || tripType == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No active trip found. Please start a shift first.'),
              backgroundColor: AppTheme.criticalAlert,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushReplacementNamed(
              context, '/busminder-start-shift-screen');
        });
      }
    } else {
      await _loadTripData();
    }
  }

  Future<void> _loadTripData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _tripType = prefs.getString('current_trip_type');
      _busId = prefs.getInt('current_bus_id');
      _tripStartTime = prefs.getString('trip_start_time');
      _userName = prefs.getString('user_name') ?? 'Busminder';

      if (_tripStartTime != null && _tripStartTime!.isNotEmpty) {
        try {
          final dt = DateTime.parse(_tripStartTime!);
          _startTripTimer(dt);
          _tripStartTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}
      }

      // Try to get bus number from API
      try {
        final busesData = await _apiService.getBusMinderBuses();
        final buses = busesData['buses'] as List<dynamic>?;
        if (buses != null && _busId != null) {
          final bus = buses.firstWhere(
            (b) => (b as Map<String, dynamic>)['id'] == _busId,
            orElse: () => null,
          );
          if (bus != null) {
            _busNumber =
                (bus as Map<String, dynamic>)['number_plate'] as String?;
          }
        }
      } catch (e) {}
      _busNumber ??= 'BUS-${_busId?.toString().padLeft(3, '0')}';

      // Load students for this bus
      if (_busId != null) {
        final childrenData =
            await _apiService.getBusChildren(_busId!, tripType: _tripType);

        final Map<int, Map<String, dynamic>> byId = {};
        for (final child in childrenData) {
          final int id = child['id'] as int;
          final studentId = id.toString();
          final savedStatus = await _loadAttendanceStatus(studentId);

          byId[id] = {
            'id': id,
            'name': '${child['first_name']} ${child['last_name']}',
            'grade': child['class_grade']?.toString() ??
                child['grade']?.toString() ??
                'N/A',
            'photo': child['photo_url'],
            'status': savedStatus ?? 'pending',
            'hasSpecialNeeds': child['has_special_needs'] ?? false,
            'parentContact': child['parent_phone'] ?? 'N/A',
            'emergencyContact': child['emergency_contact'] ?? 'N/A',
            'address': child['address'] ?? 'N/A',
            'notes': child['notes'] ?? '',
          };
        }
        _students = byId.values.toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String?> _loadAttendanceStatus(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'attendance_${_busId}_${_tripType}_$studentId';
    return prefs.getString(key);
  }

  Future<void> _saveAttendanceStatus(String studentId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'attendance_${_busId}_${_tripType}_$studentId';
    await prefs.setString(key, status);
  }

  Future<void> _clearAttendanceStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final prefix = 'attendance_${_busId}_${_tripType}_';
    for (final key in keys) {
      if (key.startsWith(prefix)) {
        await prefs.remove(key);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students.where((s) {
      final name = (s['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int get _completedCount {
    final statusKey = _tripType == 'pickup' ? 'picked_up' : 'dropped_off';
    return _students.where((s) => s['status'] == statusKey).length;
  }

  int get _absentCount =>
      _students.where((s) => s['status'] == 'absent').length;
  int get _pendingCount =>
      _students.where((s) => s['status'] == 'pending').length;

  Future<void> _handleStatusChange(int studentId, String newStatus) async {
    HapticFeedback.lightImpact();

    setState(() {
      final idx = _students.indexWhere((s) => s['id'] == studentId);
      if (idx != -1) {
        _students[idx]['status'] = newStatus;
      }
    });

    await _saveAttendanceStatus(studentId.toString(), newStatus);

    try {
      await _apiService.markAttendance(
        childId: studentId,
        status: newStatus,
        tripType: _tripType,
      );
    } catch (e) {}
  }

  void _showEndShiftConfirmation() {
    final pending = _pendingCount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('End Shift', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          pending > 0
              ? 'You have $pending students still pending. Are you sure you want to end your shift?'
              : 'Are you sure you want to end your shift?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleEndShift();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalAlert,
              foregroundColor: Colors.white,
            ),
            child: Text('End Shift'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEndShift() async {
    setState(() => _isEndingShift = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final tripId = prefs.getInt('current_trip_id');

      // Call complete trip API if we have a trip ID
      if (tripId != null) {
        await _apiService.completeTrip(
          tripId: tripId,
          totalStudents: _students.length,
          studentsCompleted: _completedCount,
          studentsAbsent: _absentCount,
          studentsPending: _pendingCount,
        );
      }

      // Clear trip data
      await prefs.remove('current_trip_type');
      await prefs.remove('current_bus_id');
      await prefs.remove('current_trip_id');
      await prefs.remove('trip_start_time');
      await prefs.remove('trip_in_progress');
      await _clearAttendanceStatuses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shift ended successfully!'),
            backgroundColor: AppTheme.successAction,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const BusMinderTripHistoryScreen(),
            settings: RouteSettings(
              arguments: {
                'showSummary': true,
                'tripSummary': {
                  'totalStudents': _students.length,
                  'studentsCompleted': _completedCount,
                  'studentsAbsent': _absentCount,
                  'studentsPending': _pendingCount,
                  'tripType': _tripType,
                  'busId': _busId,
                },
              },
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending shift. Please try again.'),
            backgroundColor: AppTheme.criticalAlert,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEndingShift = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadTripData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Theme(
        data: AppTheme.lightBusminderTheme,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundPrimary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryBusminder),
                SizedBox(height: 2.h),
                Text('Loading trip data...'),
              ],
            ),
          ),
        ),
      );
    }

    return Theme(
      data: AppTheme.lightBusminderTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        drawer: BusminderDrawerWidget(
            currentRoute: '/busminder-active-trip-screen'),
        appBar: CustomAppBar(
          title: 'Active Trip',
          subtitle:
              '$_busNumber • ${_tripType == 'pickup' ? 'Pickup' : 'Dropoff'}',
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _handleRefresh,
              icon: Icon(Icons.refresh, color: Colors.white),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/busminder-start-shift-screen',
                  (route) => false,
                );
              },
              tooltip: 'Back to Start',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryBusminder,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Trip Header Card
                    SliverToBoxAdapter(child: _buildTripHeader()),

                    // Stats Row
                    SliverToBoxAdapter(child: _buildStatsRow()),

                    // Search Bar
                    SliverToBoxAdapter(child: _buildSearchBar()),

                    // Students List
                    if (_filteredStudents.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline,
                                    size: 48, color: AppTheme.textSecondary),
                                SizedBox(height: 2.h),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No students match your search'
                                      : 'No students assigned',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildStudentCard(_filteredStudents[index]),
                          childCount: _filteredStudents.length,
                        ),
                      ),

                    SliverToBoxAdapter(child: SizedBox(height: 2.h)),
                  ],
                ),
              ),

              // End Shift Button (always visible at bottom)
              _buildEndShiftButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripHeader() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBusminder,
            AppTheme.primaryBusminder.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBusminder.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.directions_bus, color: Colors.white, size: 28),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tripType == 'pickup'
                      ? 'Morning Pickup'
                      : 'Afternoon Dropoff',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white70, size: 14),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        _tripDuration != null
                            ? 'Started at ${_tripStartTime ?? 'N/A'} • $_tripDuration'
                            : 'Started at ${_tripStartTime ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.successAction,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 1.5.w),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
              child: _buildStatChip(
                  'Total', _students.length, AppTheme.primaryBusminder)),
          SizedBox(width: 2.w),
          Expanded(
              child: _buildStatChip(
                  'Done', _completedCount, AppTheme.successAction)),
          SizedBox(width: 2.w),
          Expanded(
              child: _buildStatChip(
                  'Absent', _absentCount, AppTheme.criticalAlert)),
          SizedBox(width: 2.w),
          Expanded(
              child: _buildStatChip(
                  'Pending', _pendingCount, AppTheme.warningState)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryBusminder),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final status = student['status'] as String;
    final statusKey = _tripType == 'pickup' ? 'picked_up' : 'dropped_off';
    final isCompleted = status == statusKey;
    final isAbsent = status == 'absent';
    final isPending = status == 'pending';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppTheme.successAction.withOpacity(0.3)
              : isAbsent
                  ? AppTheme.criticalAlert.withOpacity(0.3)
                  : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryBusminder.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getInitials(student['name'] as String),
                style: TextStyle(
                  color: AppTheme.primaryBusminder,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),

          // Name and grade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.3.h),
                Row(
                  children: [
                    Text(
                      _formatGrade(student['grade']),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (student['hasSpecialNeeds'] == true) ...[
                      SizedBox(width: 2.w),
                      Icon(Icons.medical_services,
                          size: 14, color: AppTheme.warningState),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Status indicator
          if (isCompleted)
            GestureDetector(
              onTap: () => _handleStatusChange(student['id'] as int, 'pending'),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: AppTheme.successAction.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: AppTheme.successAction),
                    SizedBox(width: 1.w),
                    Text(
                      _tripType == 'pickup'
                          ? 'Picked Up • Tap to change'
                          : 'Dropped Off • Tap to change',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successAction,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isAbsent)
            GestureDetector(
              onTap: () => _handleStatusChange(student['id'] as int, 'pending'),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: AppTheme.criticalAlert.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 16, color: AppTheme.criticalAlert),
                    SizedBox(width: 1.w),
                    Text(
                      'Absent • Tap to change',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.criticalAlert,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Action buttons for pending
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.check,
                  color: AppTheme.successAction,
                  onTap: () =>
                      _handleStatusChange(student['id'] as int, statusKey),
                ),
                SizedBox(width: 2.w),
                _buildActionButton(
                  icon: Icons.close,
                  color: AppTheme.criticalAlert,
                  onTap: () =>
                      _handleStatusChange(student['id'] as int, 'absent'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildEndShiftButton() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isEndingShift ? null : _showEndShiftConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalAlert,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isEndingShift
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_circle, size: 22),
                      SizedBox(width: 2.w),
                      Text(
                        'End Shift',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  }

  String _formatGrade(dynamic grade) {
    if (grade == null) return 'Grade N/A';

    final gradeStr = grade.toString();
    if (gradeStr.toLowerCase().startsWith('grade')) {
      return gradeStr;
    }
    return 'Grade $gradeStr';
  }
}
