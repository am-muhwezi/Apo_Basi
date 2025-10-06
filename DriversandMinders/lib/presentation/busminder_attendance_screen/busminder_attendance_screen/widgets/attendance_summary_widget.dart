import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Bottom attendance summary widget with progress indicators
class AttendanceSummaryWidget extends StatelessWidget {
  final int totalStudents;
  final int pickedUpCount;
  final int droppedOffCount;
  final int pendingCount;

  const AttendanceSummaryWidget({
    super.key,
    required this.totalStudents,
    required this.pickedUpCount,
    required this.droppedOffCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightBusminderTheme;
    final pickupProgress =
        totalStudents > 0 ? pickedUpCount / totalStudents : 0.0;
    final dropoffProgress =
        totalStudents > 0 ? droppedOffCount / totalStudents : 0.0;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 1.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBusminder.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '$totalStudents Total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primaryBusminder,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Progress Indicators
          Row(
            children: [
              // Pickup Progress
              Expanded(
                child: _buildProgressIndicator(
                  context,
                  'Picked Up',
                  pickedUpCount,
                  pickupProgress,
                  AppTheme.successAction,
                  Icons.check_circle,
                ),
              ),

              SizedBox(width: 4.w),

              // Dropoff Progress
              Expanded(
                child: _buildProgressIndicator(
                  context,
                  'Dropped Off',
                  droppedOffCount,
                  dropoffProgress,
                  AppTheme.warningState,
                  Icons.home_filled,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Pending Count
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'pending',
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  '$pendingCount Pending',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    int count,
    double progress,
    Color color,
    IconData icon,
  ) {
    final theme = AppTheme.lightBusminderTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and Count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: icon.codePoint.toString(),
                  color: color,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              count.toString(),
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: 1.h),

        // Progress Bar
        Container(
          height: 1.h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ),

        SizedBox(height: 0.5.h),

        // Percentage
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
