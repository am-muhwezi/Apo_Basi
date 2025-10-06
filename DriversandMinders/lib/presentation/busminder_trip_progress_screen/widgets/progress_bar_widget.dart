import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProgressBarWidget extends StatelessWidget {
  final double progressPercentage;
  final List<Map<String, dynamic>> milestones;

  const ProgressBarWidget({
    super.key,
    required this.progressPercentage,
    required this.milestones,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Route Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '${progressPercentage.toInt()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBusminder,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: (progressPercentage / 100) * 82.w,
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBusminder,
                      AppTheme.primaryBusminderLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ..._buildMilestoneIndicators(context),
            ],
          ),
          SizedBox(height: 2.h),
          _buildMilestonesList(context),
        ],
      ),
    );
  }

  List<Widget> _buildMilestoneIndicators(BuildContext context) {
    final theme = Theme.of(context);
    List<Widget> indicators = [];

    for (int i = 0; i < milestones.length; i++) {
      final milestone = milestones[i];
      final position = (milestone['position'] as double? ?? 0.0) / 100;
      final isCompleted = milestone['completed'] as bool? ?? false;

      indicators.add(
        Positioned(
          left: position * 82.w - 8,
          top: -4,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successAction
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isCompleted
                    ? AppTheme.successAction
                    : theme.colorScheme.outline,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? CustomIconWidget(
                    iconName: 'check',
                    color: Colors.white,
                    size: 10,
                  )
                : null,
          ),
        ),
      );
    }

    return indicators;
  }

  Widget _buildMilestonesList(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: milestones.map((milestone) {
        final name = milestone['name'] as String? ?? 'Unknown Stop';
        final isCompleted = milestone['completed'] as bool? ?? false;
        final studentCount = milestone['studentCount'] as int? ?? 0;

        return Container(
          margin: EdgeInsets.only(bottom: 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.successAction.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.successAction.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName:
                    isCompleted ? 'check_circle' : 'radio_button_unchecked',
                color: isCompleted
                    ? AppTheme.successAction
                    : theme.colorScheme.outline,
                size: 20,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$studentCount students',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

