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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
      print('Error loading trip history: $e');
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
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBusminder,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleBackPress,
          ),
          title: Text(
            _showSummary ? 'Trip Completed' : 'Trip History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            // Trip Summary (if just completed)
            if (_showSummary && _tripSummary != null) _buildTripSummaryCard(),

            // Filter tabs
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterButton(
                      'Completed',
                      'completed',
                      Icons.check_circle,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: _buildFilterButton(
                      'All Trips',
                      'all',
                      Icons.list,
                    ),
                  ),
                ],
              ),
            ),

          // Trip list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBusminder,
                    ),
                  )
                : _trips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 60.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No trips found',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primaryBusminder,
                        onRefresh: _loadTripHistory,
                        child: ListView.builder(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _trips.length,
                          itemBuilder: (context, index) {
                            final trip = _trips[index];
                            return _buildTripCard(trip);
                          },
                        ),
                      ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummaryCard() {
    final totalStudents = _tripSummary!['totalStudents'] ?? 0;
    final studentsCompleted = _tripSummary!['studentsCompleted'] ?? 0;
    final studentsAbsent = _tripSummary!['studentsAbsent'] ?? 0;
    final studentsPending = _tripSummary!['studentsPending'] ?? 0;
    final tripType = _tripSummary!['tripType'] ?? 'pickup';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBusminder,
            AppTheme.primaryBusminderLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBusminder.withValues(alpha: 0.3),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon and message
          Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 40.sp,
          ),
          SizedBox(height: 1.h),
          Text(
            'Trip Completed Successfully!',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            tripType == 'pickup' ? 'Morning Pickup' : 'Afternoon Dropoff',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 2.h),

          // Summary stats
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trip Summary',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStatItem(
                      'Total',
                      totalStudents.toString(),
                      Icons.people,
                    ),
                    _buildSummaryStatItem(
                      'Completed',
                      studentsCompleted.toString(),
                      Icons.check_circle,
                    ),
                    _buildSummaryStatItem(
                      'Absent',
                      studentsAbsent.toString(),
                      Icons.person_off,
                    ),
                    _buildSummaryStatItem(
                      'Pending',
                      studentsPending.toString(),
                      Icons.schedule,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),

          // Dismiss button
          TextButton(
            onPressed: () {
              setState(() {
                _showSummary = false;
                _tripSummary = null;
              });
            },
            child: Text(
              'Dismiss',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18.sp),
        SizedBox(height: 0.3.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
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
                    color: tripType == 'pickup'
                        ? Colors.orange
                        : Colors.indigo,
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
