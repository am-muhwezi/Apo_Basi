import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';

class BusMinderTripHistoryScreen extends StatefulWidget {
  const BusMinderTripHistoryScreen({super.key});

  @override
  State<BusMinderTripHistoryScreen> createState() =>
      _BusMinderTripHistoryScreenState();
}

class _BusMinderTripHistoryScreenState
    extends State<BusMinderTripHistoryScreen> {
  final ApiService _apiService = ApiService();
  ThemeData _busminderTheme = AppTheme.lightBusminderTheme;
  List<dynamic> _trips = [];
  bool _isLoading = true;
  String _selectedFilter = 'completed'; // completed, all
  bool _showSummary = false;
  Map<String, dynamic>? _tripSummary;

  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments passed from previous screen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['showSummary'] == true) {
      setState(() {
        _showSummary = true;
        _tripSummary = args['tripSummary'] as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _loadTripHistory() async {
    setState(() => _isLoading = true);
    try {
      final trips = await _apiService.getTripHistory(
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      if (mounted) {
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _trips = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trip history'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleBackPress() {
    if (_showSummary) {
      // Coming from complete trip - go to home
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/busminder-start-shift-screen',
        (route) => false,
      );
    } else {
      // Coming from drawer - normal back
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (ctx, themeMode, _) {
        _busminderTheme = themeMode == ThemeMode.dark
            ? AppTheme.darkBusminderTheme
            : AppTheme.lightBusminderTheme;
        return Theme(
          data: _busminderTheme,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (!didPop) _handleBackPress();
            },
            child: Scaffold(
              backgroundColor: _busminderTheme.scaffoldBackgroundColor,
              body: _showSummary && _tripSummary != null
                  ? _buildModernSummaryView()
                  : _buildLoadingView(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildModernSummaryView() {
    final cs = _busminderTheme.colorScheme;
    final totalStudents = _tripSummary!['totalStudents'] ?? 0;
    final studentsCompleted = _tripSummary!['studentsCompleted'] ?? 0;
    final studentsAbsent = _tripSummary!['studentsAbsent'] ?? 0;
    final tripType = _tripSummary!['tripType'] ?? 'pickup';
    final completionRate = totalStudents > 0
        ? ((studentsCompleted / totalStudents) * 100).round()
        : 0;
    final isPickup = tripType == 'pickup';

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Column(
                children: [
                  SizedBox(height: 5.h),

                  // ── Success icon ──────────────────────────────────────────
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 52),
                  ),

                  SizedBox(height: 3.h),

                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    'Shift Complete!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isPickup ? 'Pickup Trip' : 'Dropoff Trip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // ── Attendance rate card ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        vertical: 3.h, horizontal: 5.w),
                    decoration: BoxDecoration(
                      color: _busminderTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cs.outline.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$completionRate',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: 0.6.h, left: 2),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Attendance Rate',
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completionRate / 100,
                            minHeight: 7,
                            backgroundColor:
                                cs.outline.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // ── Stats row ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _busminderTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cs.outline.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(cs, '$totalStudents', 'Total',
                            cs.primary),
                        _buildStatDivider(cs),
                        _buildStatItem(cs, '$studentsCompleted', 'Done',
                            const Color(0xFF2E7D32)),
                        _buildStatDivider(cs),
                        _buildStatItem(cs, '$studentsAbsent', 'Absent',
                            cs.error),
                      ],
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // ── Done button (pinned at bottom) ────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 3.h),
            child: GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/busminder-start-shift-screen',
                (route) => false,
              ),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary,
                      cs.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      ColorScheme cs, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme cs) => Container(
        width: 1,
        height: 36,
        color: cs.outline.withValues(alpha: 0.2),
      );

  Widget _buildFilterButton(String label, String filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _loadTripHistory();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 18.sp,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final tripType = trip['type'] ?? 'pickup';
    final status = trip['status'] ?? 'completed';
    final busNumber = trip['busNumber'] ?? 'N/A';
    final route = trip['route'] ?? 'Unknown Route';
    final startTime = trip['startTime'];
    final endTime = trip['endTime'];

    // Summary data
    final totalStudents = trip['totalStudents'] ?? 0;
    final studentsCompleted = trip['studentsCompleted'] ?? 0;
    final studentsAbsent = trip['studentsAbsent'] ?? 0;
    final studentsPending = trip['studentsPending'] ?? 0;

    // Parse times
    DateTime? startDateTime;
    DateTime? endDateTime;
    if (startTime != null) {
      startDateTime = DateTime.parse(startTime);
    }
    if (endTime != null) {
      endDateTime = DateTime.parse(endTime);
    }

    // Calculate duration
    String duration = 'N/A';
    if (startDateTime != null && endDateTime != null) {
      final diff = endDateTime.difference(startDateTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours > 0) {
        duration = '${hours}h ${minutes}m';
      } else {
        duration = '${minutes}m';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with trip type and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    tripType == 'pickup'
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined,
                    color: tripType == 'pickup' ? Colors.orange : Colors.indigo,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    tripType == 'pickup'
                        ? 'Morning Pickup'
                        : 'Afternoon Dropoff',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Bus and route info
          Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.grey, size: 16.sp),
              SizedBox(width: 2.w),
              Text(
                'Bus $busNumber',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                '•',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  route,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),

          // Time info
          if (startDateTime != null)
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey, size: 16.sp),
                SizedBox(width: 2.w),
                Text(
                  _formatTime(startDateTime),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                if (endDateTime != null) ...[
                  Text(
                    ' - ${_formatTime(endDateTime)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '($duration)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

          // Summary (if trip is completed)
          if (status == 'completed' && totalStudents > 0) ...[
            SizedBox(height: 2.h),
            Divider(color: Theme.of(context).colorScheme.outline),
            SizedBox(height: 1.h),
            Text(
              'Trip Summary',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total',
                    totalStudents.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Completed',
                    studentsCompleted.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Absent',
                    studentsAbsent.toString(),
                    Icons.person_off,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pending',
                    studentsPending.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
