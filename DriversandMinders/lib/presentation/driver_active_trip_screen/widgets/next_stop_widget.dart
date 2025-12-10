import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Prominent widget showing the next stop for the driver
/// Designed for at-a-glance viewing while driving
class NextStopWidget extends StatelessWidget {
  final Map<String, dynamic>? nextStudent;
  final int remainingStops;
  final VoidCallback onMarkPickedUp;

  const NextStopWidget({
    super.key,
    required this.nextStudent,
    required this.remainingStops,
    required this.onMarkPickedUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (nextStudent == null) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.successAction,
              AppTheme.successAction.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.successAction.withValues(alpha: 0.3),
              offset: Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.textOnPrimary,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'All Students Picked Up!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Ready to end trip',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textOnPrimary.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final studentName = nextStudent!["name"] as String? ?? "Unknown Student";
    final studentGrade = nextStudent!["grade"] as String? ?? "N/A";
    final stopName = nextStudent!["stopName"] as String? ?? "Unknown Stop";
    final specialNotes = nextStudent!["specialNotes"] as String?;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryDriver,
            AppTheme.primaryDriver.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDriver.withValues(alpha: 0.3),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'navigation',
                        color: AppTheme.textOnPrimary,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'NEXT STOP',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.textOnPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$remainingStops Remaining',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stop Address - Large and prominent
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'location_on',
                  color: AppTheme.textOnPrimary,
                  size: 28,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    stopName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Student Info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                // Student Avatar
                Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryDriver,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Grade $studentGrade',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textOnPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Special Notes if present
          if (specialNotes != null && specialNotes.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.warningState,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      specialNotes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 3.h),

          // Mark Picked Up Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
            decoration: BoxDecoration(
              color: AppTheme.textOnPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onMarkPickedUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successAction,
                foregroundColor: AppTheme.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.textOnPrimary,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Student Picked Up',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
