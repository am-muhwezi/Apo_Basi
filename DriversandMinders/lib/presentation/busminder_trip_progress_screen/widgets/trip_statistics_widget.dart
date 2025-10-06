import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TripStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statisticsData;

  const TripStatisticsWidget({
    super.key,
    required this.statisticsData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalStudents = statisticsData['totalStudents'] as int? ?? 0;
    final attendanceRate = statisticsData['attendanceRate'] as double? ?? 0.0;
    final onTimePerformance =
        statisticsData['onTimePerformance'] as double? ?? 0.0;
    final completedStops = statisticsData['completedStops'] as int? ?? 0;
    final totalStops = statisticsData['totalStops'] as int? ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Students',
                  totalStudents.toString(),
                  CustomIconWidget(
                    iconName: 'school',
                    color: AppTheme.primaryBusminder,
                    size: 24,
                  ),
                  AppTheme.primaryBusminder,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Attendance Rate',
                  '${attendanceRate.toInt()}%',
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.successAction,
                    size: 24,
                  ),
                  AppTheme.successAction,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'On-Time Performance',
                  '${onTimePerformance.toInt()}%',
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: onTimePerformance >= 80
                        ? AppTheme.successAction
                        : AppTheme.warningState,
                    size: 24,
                  ),
                  onTimePerformance >= 80
                      ? AppTheme.successAction
                      : AppTheme.warningState,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Stops Progress',
                  '$completedStops/$totalStops',
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: AppTheme.primaryBusminder,
                    size: 24,
                  ),
                  AppTheme.primaryBusminder,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildPerformanceIndicator(
              context, attendanceRate, onTimePerformance),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Widget icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          icon,
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(
    BuildContext context,
    double attendanceRate,
    double onTimePerformance,
  ) {
    final theme = Theme.of(context);
    final averagePerformance = (attendanceRate + onTimePerformance) / 2;

    Color performanceColor;
    String performanceText;
    IconData performanceIcon;

    if (averagePerformance >= 90) {
      performanceColor = AppTheme.successAction;
      performanceText = 'Excellent Performance';
      performanceIcon = Icons.star;
    } else if (averagePerformance >= 75) {
      performanceColor = AppTheme.primaryBusminder;
      performanceText = 'Good Performance';
      performanceIcon = Icons.thumb_up;
    } else if (averagePerformance >= 60) {
      performanceColor = AppTheme.warningState;
      performanceText = 'Average Performance';
      performanceIcon = Icons.info;
    } else {
      performanceColor = AppTheme.criticalAlert;
      performanceText = 'Needs Improvement';
      performanceIcon = Icons.warning;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            performanceColor.withValues(alpha: 0.1),
            performanceColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: performanceColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: performanceColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: performanceIcon.codePoint.toString(),
              color: performanceColor,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performanceText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: performanceColor,
                  ),
                ),
                Text(
                  'Overall trip performance: ${averagePerformance.toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: performanceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${averagePerformance.toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

