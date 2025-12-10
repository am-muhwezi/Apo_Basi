import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Compact widget showing upcoming stops after the next stop
/// Shows only not-picked-up students in order
class UpcomingStopsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingStudents;
  final VoidCallback? onViewAll;

  const UpcomingStopsWidget({
    super.key,
    required this.upcomingStudents,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (upcomingStudents.isEmpty) {
      return SizedBox.shrink();
    }

    // Show only first 3 upcoming stops
    final displayStudents = upcomingStudents.take(3).toList();
    final hasMore = upcomingStudents.length > 3;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Stops',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasMore && onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All (${upcomingStudents.length})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDriver,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          ...displayStudents.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < displayStudents.length - 1 ? 2.h : 0),
              child: _buildUpcomingStopRow(context, student, index + 2),
            );
          }),
          if (hasMore && onViewAll == null) ...[
            SizedBox(height: 1.h),
            Center(
              child: Text(
                '+${upcomingStudents.length - 3} more stops',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingStopRow(BuildContext context, Map<String, dynamic> student, int position) {
    final theme = Theme.of(context);
    final studentName = student["name"] as String? ?? "Unknown";
    final stopName = student["stopName"] as String? ?? "Unknown Stop";

    return Row(
      children: [
        // Position number
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.primaryDriver.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$position',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.primaryDriver,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        // Student info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.3.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: AppTheme.textSecondary,
                    size: 12,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      stopName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
