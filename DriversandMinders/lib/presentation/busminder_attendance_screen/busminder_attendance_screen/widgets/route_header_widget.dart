import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Header widget displaying current route information and trip status
class RouteHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> routeInfo;
  final int totalStudents;

  const RouteHeaderWidget({
    super.key,
    required this.routeInfo,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightBusminderTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBusminder,
            AppTheme.primaryBusminderLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBusminder.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Name and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeOfDay()}!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textOnPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      routeInfo['routeName'] as String? ?? 'Route Unknown',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Trip Status Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: _getTripStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: _getTripStatusColor(),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: _getTripStatusIcon(),
                      color: _getTripStatusColor(),
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _getTripStatusText(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _getTripStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Route Details
          Row(
            children: [
              // Student Count
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Students',
                  totalStudents.toString(),
                  'people',
                  AppTheme.textOnPrimary,
                ),
              ),

              SizedBox(width: 3.w),

              // Trip Time
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Started',
                  routeInfo['startTime'] as String? ?? '--:--',
                  'schedule',
                  AppTheme.textOnPrimary,
                ),
              ),

              SizedBox(width: 3.w),

              // Route Type
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Type',
                  routeInfo['tripType'] as String? ?? 'Regular',
                  'directions_bus',
                  AppTheme.textOnPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    String iconName,
    Color color,
  ) {
    final theme = AppTheme.lightBusminderTheme;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 20,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Color _getTripStatusColor() {
    final status = routeInfo['status'] as String? ?? 'active';
    switch (status) {
      case 'active':
        return AppTheme.successAction;
      case 'completed':
        return AppTheme.primaryBusminder;
      case 'paused':
        return AppTheme.warningState;
      default:
        return AppTheme.textOnPrimary;
    }
  }

  String _getTripStatusIcon() {
    final status = routeInfo['status'] as String? ?? 'active';
    switch (status) {
      case 'active':
        return 'play_circle';
      case 'completed':
        return 'check_circle';
      case 'paused':
        return 'pause_circle';
      default:
        return 'radio_button_unchecked';
    }
  }

  String _getTripStatusText() {
    final status = routeInfo['status'] as String? ?? 'active';
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      default:
        return 'Unknown';
    }
  }
}
