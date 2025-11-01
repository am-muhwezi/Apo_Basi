import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Modern floating attendance summary widget with compact stats
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
    final completedCount = pickedUpCount + droppedOffCount;
    final completionProgress = totalStudents > 0 ? completedCount / totalStudents : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryBusminder.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppTheme.primaryBusminder.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBusminder.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Ring with Stats
          Row(
            children: [
              // Circular Progress Indicator
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Circle
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.backgroundSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    // Progress Circle
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        value: completionProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.successAction,
                        ),
                      ),
                    ),
                    // Center Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(completionProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryBusminder,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 5.w),

              // Stats Grid
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactStat(
                            context,
                            completedCount.toString(),
                            'Marked',
                            AppTheme.successAction,
                            Icons.check_circle,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: _buildCompactStat(
                            context,
                            pendingCount.toString(),
                            'Pending',
                            AppTheme.warningState,
                            Icons.pending,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _buildTotalBar(context, totalStudents, completedCount),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(
    BuildContext context,
    String count,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 0.5.h),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBar(BuildContext context, int total, int completed) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryBusminder.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            color: AppTheme.primaryBusminder,
            size: 16,
          ),
          SizedBox(width: 2.w),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              children: [
                TextSpan(
                  text: '$completed',
                  style: TextStyle(
                    color: AppTheme.successAction,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' of '),
                TextSpan(
                  text: '$total',
                  style: TextStyle(
                    color: AppTheme.primaryBusminder,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' students marked'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
