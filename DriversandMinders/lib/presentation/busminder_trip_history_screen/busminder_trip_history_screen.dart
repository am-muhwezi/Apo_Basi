import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/api_service.dart';

class BusMinderTripHistoryScreen extends StatefulWidget {
  const BusMinderTripHistoryScreen({super.key});

  @override
  State<BusMinderTripHistoryScreen> createState() =>
      _BusMinderTripHistoryScreenState();
}

class _BusMinderTripHistoryScreenState
    extends State<BusMinderTripHistoryScreen> {
  final ApiService _apiService = ApiService();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF8FAFB),
        body: _showSummary && _tripSummary != null
            ? _buildModernSummaryView()
            : _buildLoadingView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(color: AppTheme.primaryBusminder),
    );
  }

  Widget _buildModernSummaryView() {
    final totalStudents = _tripSummary!['totalStudents'] ?? 0;
    final studentsCompleted = _tripSummary!['studentsCompleted'] ?? 0;
    final studentsAbsent = _tripSummary!['studentsAbsent'] ?? 0;
    final tripType = _tripSummary!['tripType'] ?? 'pickup';
    final completionRate = totalStudents > 0
        ? ((studentsCompleted / totalStudents) * 100).round()
        : 0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          children: [
            SizedBox(height: 4.h),

            // Success animation area
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated check icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successAction,
                          AppTheme.successAction.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successAction.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Shift Complete!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    tripType == 'pickup'
                        ? 'Morning Pickup'
                        : 'Afternoon Dropoff',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Stats cards
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Completion rate card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: Offset(0, 4),
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
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.successAction,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 0.8.h),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.successAction,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Attendance Rate',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard('$totalStudents', 'Total',
                              Icons.people_outline, AppTheme.primaryBusminder)),
                      SizedBox(width: 3.w),
                      Expanded(
                          child: _buildStatCard(
                              '$studentsCompleted',
                              'Done',
                              Icons.check_circle_outline,
                              AppTheme.successAction)),
                      SizedBox(width: 3.w),
                      Expanded(
                          child: _buildStatCard('$studentsAbsent', 'Absent',
                              Icons.cancel_outlined, AppTheme.criticalAlert)),
                    ],
                  ),
                ],
              ),
            ),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/busminder-start-shift-screen',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBusminder,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
          color: isSelected ? AppTheme.primaryBusminder : Colors.grey[200],
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
        border: Border.all(color: AppTheme.borderLight),
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
                      color: AppTheme.textPrimary,
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
                  color: AppTheme.textPrimary,
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
                      color: AppTheme.primaryBusminder,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

          // Summary (if trip is completed)
          if (status == 'completed' && totalStudents > 0) ...[
            SizedBox(height: 2.h),
            Divider(color: AppTheme.borderLight),
            SizedBox(height: 1.h),
            Text(
              'Trip Summary',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
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
            color: AppTheme.textPrimary,
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
