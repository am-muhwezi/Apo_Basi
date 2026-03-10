import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
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

  // Busminder theme — set in build() so helper methods use the correct theme
  ThemeData _busminderTheme = AppTheme.lightBusminderTheme;

  // Loading states
  bool _isLoading = true;
  bool _isEndingShift = false;
  String? _errorMessage;

  // Trip information
  int? _busId;
  String? _tripType;
  String? _tripStartTime;
  String? _busNumber;
  String? _driverName;
  String? _routeName;
  String? _userName;

  // Student data
  List<Map<String, dynamic>> _students = [];
  String _searchQuery = '';
  String? _tripDuration;
  String _clockTime = '';
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
        _clockTime =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
    }

    update();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) update();
    });
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
              backgroundColor: _busminderTheme.colorScheme.error,
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

      // Pull rich trip metadata (driver, route, bus number) from active trip API
      try {
        final tripData = await _apiService.getBusminderActiveTrip();
        if (tripData != null) {
          _busNumber ??= tripData['busNumber'] as String?;
          _driverName = tripData['driverName'] as String?;
          _routeName = tripData['route'] as String?;
          // Use backend startTime if local prefs didn't have it
          final rawStart = tripData['startTime'] as String?;
          if (rawStart != null && _tripStartTime == null) {
            try {
              final dt = DateTime.parse(rawStart).toLocal();
              _startTripTimer(dt);
              _tripStartTime =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
        }
      } catch (_) {}

      // Fallback: bus number from buses list
      if (_busNumber == null) {
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
        } catch (_) {}
      }
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
              backgroundColor: _busminderTheme.colorScheme.error,
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
            backgroundColor: _busminderTheme.colorScheme.secondary,
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
            backgroundColor: _busminderTheme.colorScheme.error,
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (ctx, themeMode, _) {
        _busminderTheme = themeMode == ThemeMode.dark
            ? AppTheme.darkBusminderTheme
            : AppTheme.lightBusminderTheme;
        final busTheme = _busminderTheme;

        if (_isLoading) {
          return Theme(
            data: busTheme,
            child: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                          color: busTheme.colorScheme.primary),
                      SizedBox(height: 2.h),
                      const Text('Loading trip data...'),
                    ],
                  ),
                )),
          );
        }

        return Theme(
          data: busTheme,
          child: Scaffold(
        drawer: BusminderDrawerWidget(
            currentRoute: '/busminder-active-trip-screen'),
        appBar: CustomAppBar(
          title: _tripType == 'pickup' ? 'Pickup Trip' : 'Dropoff Trip',
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.home_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/busminder-start-shift-screen',
                  (route) => false,
                );
              },
              tooltip: 'Back to Home',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: _busminderTheme.colorScheme.primary,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildTripHeader()),
                    SliverToBoxAdapter(child: _buildStatsRow()),
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: _buildStudentsHeader()),
                    if (_filteredStudents.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline_rounded,
                                    size: 52,
                                    color: _busminderTheme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No students match your search'
                                      : 'No students assigned',
                                  style: TextStyle(
                                      color: _busminderTheme.colorScheme.onSurfaceVariant,
                                      fontSize: 14),
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
              _buildEndShiftButton(),
            ],
          ),
        ),
        ),
      );
      },
    );
  }

  // ── Trip summary header ─────────────────────────────────────────────────────
  Widget _buildTripHeader() {
    final cs = _busminderTheme.colorScheme;
    final isPickup = _tripType == 'pickup';
    final total = _students.length;
    final done = _completedCount;
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _busminderTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + title + timer pill ──────────────────────────
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPickup
                      ? Icons.arrow_circle_up_rounded
                      : Icons.arrow_circle_down_rounded,
                  color: cs.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPickup ? 'Pickup Trip' : 'Dropoff Trip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              // Right side: current time + elapsed duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Current wall-clock time
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _clockTime.isEmpty ? '--:--' : _clockTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Elapsed duration
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _tripDuration ?? '00:00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Info grid: 2×2 ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  cs,
                  Icons.directions_bus_rounded,
                  'Bus',
                  _busNumber ?? '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoTile(
                  cs,
                  Icons.route_rounded,
                  'Route',
                  _routeName ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  cs,
                  Icons.person_rounded,
                  'Driver',
                  _driverName ?? '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoTile(
                  cs,
                  Icons.schedule_rounded,
                  'Started',
                  _tripStartTime ?? '--:--',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done of $total ${isPickup ? 'picked up' : 'dropped off'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: cs.outline.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      ColorScheme cs, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats bar ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final cs = _busminderTheme.colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _busminderTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _buildStatItem('Total', _students.length, cs.primary),
          _buildStatDivider(cs),
          _buildStatItem('Done', _completedCount, const Color(0xFF2E7D32)),
          _buildStatDivider(cs),
          _buildStatItem('Absent', _absentCount, cs.error),
          _buildStatDivider(cs),
          _buildStatItem('Pending', _pendingCount, const Color(0xFFE65100)),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme cs) => Container(
        width: 1,
        height: 36,
        color: cs.outline.withValues(alpha: 0.2),
      );

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _busminderTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final cs = _busminderTheme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontSize: 15, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Search students...',
          hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded,
              color: cs.onSurfaceVariant, size: 22),
          filled: true,
          fillColor: _busminderTheme.cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: cs.outline.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: cs.outline.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Students section label ───────────────────────────────────────────────────
  Widget _buildStudentsHeader() {
    final cs = _busminderTheme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0.5.h),
      child: Row(
        children: [
          Text(
            'Students',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${_filteredStudents.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Student card ─────────────────────────────────────────────────────────────
  Widget _buildStudentCard(Map<String, dynamic> student) {
    final cs = _busminderTheme.colorScheme;
    final status = student['status'] as String;
    final statusKey = _tripType == 'pickup' ? 'picked_up' : 'dropped_off';
    final isCompleted = status == statusKey;
    final isAbsent = status == 'absent';
    const doneColor = Color(0xFF2E7D32);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _busminderTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status accent bar
              Container(
                width: 4,
                color: isCompleted
                    ? doneColor
                    : isAbsent
                        ? cs.error
                        : cs.outline.withValues(alpha: 0.25),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 3.5.w, vertical: 1.4.h),
                  child: Row(
                    children: [
                      // Circle avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(student['name'] as String),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + grade
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              student['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  _formatGrade(student['grade']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                if (student['hasSpecialNeeds'] == true) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                      Icons.medical_services_outlined,
                                      size: 13,
                                      color: cs.tertiary),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Right: pill or action buttons
                      if (isCompleted)
                        _buildStatusPill(
                          label: _tripType == 'pickup'
                              ? 'Picked Up'
                              : 'Dropped',
                          color: doneColor,
                          icon: Icons.check_circle_outline_rounded,
                          onTap: () => _handleStatusChange(
                              student['id'] as int, 'pending'),
                        )
                      else if (isAbsent)
                        _buildStatusPill(
                          label: 'Absent',
                          color: cs.error,
                          icon: Icons.cancel_outlined,
                          onTap: () => _handleStatusChange(
                              student['id'] as int, 'pending'),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRoundButton(
                              icon: Icons.check_rounded,
                              color: doneColor,
                              onTap: () => _handleStatusChange(
                                  student['id'] as int, statusKey),
                            ),
                            const SizedBox(width: 8),
                            _buildRoundButton(
                              icon: Icons.close_rounded,
                              color: cs.error,
                              onTap: () => _handleStatusChange(
                                  student['id'] as int, 'absent'),
                            ),
                          ],
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

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ── End shift button ─────────────────────────────────────────────────────────
  Widget _buildEndShiftButton() {
    final cs = _busminderTheme.colorScheme;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.h),
        decoration: BoxDecoration(
          color: _busminderTheme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _isEndingShift ? null : _showEndShiftConfirmation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.error, cs.error.withValues(alpha: 0.85)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isEndingShift
                  ? []
                  : [
                      BoxShadow(
                        color: cs.error.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: _isEndingShift
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop_circle_outlined,
                            color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'End Shift',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            letterSpacing: 0.3,
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
