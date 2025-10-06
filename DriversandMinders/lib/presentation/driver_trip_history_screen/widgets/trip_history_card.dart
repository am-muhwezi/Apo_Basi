import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TripHistoryCard extends StatelessWidget {
  final Map<String, dynamic> tripData;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onShareReport;
  final VoidCallback? onAddNotes;

  const TripHistoryCard({
    super.key,
    required this.tripData,
    this.onTap,
    this.onViewDetails,
    this.onShareReport,
    this.onAddNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String routeName =
        (tripData['routeName'] as String?) ?? 'Unknown Route';
    final String date = (tripData['date'] as String?) ?? '';
    final String duration = (tripData['duration'] as String?) ?? '';
    final int studentCount = (tripData['studentCount'] as int?) ?? 0;
    final String status = (tripData['status'] as String?) ?? 'completed';
    final String startTime = (tripData['startTime'] as String?) ?? '';
    final String endTime = (tripData['endTime'] as String?) ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(tripData['id']),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onViewDetails?.call(),
              backgroundColor: AppTheme.primaryDriver,
              foregroundColor: AppTheme.textOnPrimary,
              icon: Icons.visibility,
              label: 'View',
              borderRadius: BorderRadius.circular(8.0),
            ),
            SlidableAction(
              onPressed: (_) => onShareReport?.call(),
              backgroundColor: AppTheme.successAction,
              foregroundColor: AppTheme.textOnPrimary,
              icon: Icons.share,
              label: 'Share',
              borderRadius: BorderRadius.circular(8.0),
            ),
            SlidableAction(
              onPressed: (_) => onAddNotes?.call(),
              backgroundColor: AppTheme.warningState,
              foregroundColor: AppTheme.textOnPrimary,
              icon: Icons.note_add,
              label: 'Notes',
              borderRadius: BorderRadius.circular(8.0),
            ),
          ],
        ),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with route name and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          routeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      _buildStatusBadge(context, status),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  // Date and time row
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'calendar_today',
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        date,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      CustomIconWidget(
                        iconName: 'access_time',
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '$startTime - $endTime',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  // Duration and student count row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'timer',
                              color: AppTheme.primaryDriver,
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Duration: $duration',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'people',
                            color: AppTheme.primaryDriver,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '$studentCount Students',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 1.h),

                  // Swipe hint
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 0.5.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Swipe left for actions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        CustomIconWidget(
                          iconName: 'swipe_left',
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 12,
                        ),
                      ],
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

  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = AppTheme.successAction;
        textColor = AppTheme.textOnPrimary;
        displayText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = AppTheme.criticalAlert;
        textColor = AppTheme.textOnPrimary;
        displayText = 'Cancelled';
        break;
      case 'delayed':
        backgroundColor = AppTheme.warningState;
        textColor = AppTheme.textOnPrimary;
        displayText = 'Delayed';
        break;
      default:
        backgroundColor = theme.colorScheme.outline;
        textColor = theme.colorScheme.onSurface;
        displayText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        displayText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

