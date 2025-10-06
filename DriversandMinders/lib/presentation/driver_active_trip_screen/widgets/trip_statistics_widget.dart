import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Trip statistics cards showing key metrics
class TripStatisticsWidget extends StatelessWidget {
  final int studentsPickedUp;
  final int totalStudents;
  final int remainingStops;
  final String estimatedArrival;

  const TripStatisticsWidget({
    super.key,
    required this.studentsPickedUp,
    required this.totalStudents,
    required this.remainingStops,
    required this.estimatedArrival,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          // Students picked up
          Expanded(
            child: _buildStatCard(
              context,
              icon: 'people',
              title: 'Students',
              value: '$studentsPickedUp/$totalStudents',
              subtitle: 'Picked Up',
              color: AppTheme.successAction,
            ),
          ),

          SizedBox(width: 3.w),

          // Remaining stops
          Expanded(
            child: _buildStatCard(
              context,
              icon: 'location_on',
              title: 'Stops',
              value: remainingStops.toString(),
              subtitle: 'Remaining',
              color: AppTheme.warningState,
            ),
          ),

          SizedBox(width: 3.w),

          // Estimated arrival
          Expanded(
            child: _buildStatCard(
              context,
              icon: 'schedule',
              title: 'ETA',
              value: estimatedArrival,
              subtitle: 'Arrival',
              color: AppTheme.primaryDriver,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: color,
              size: 20,
            ),
          ),

          SizedBox(height: 1.h),

          // Value
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 0.5.h),

          // Title and subtitle
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

