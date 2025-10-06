import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TripTimelineWidget extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const TripTimelineWidget({
    super.key,
    required this.tripData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStop = tripData['currentStop'] as String? ?? 'Unknown Stop';
    final nextStop = tripData['nextStop'] as String? ?? 'Final Destination';
    final estimatedArrival = tripData['estimatedArrival'] as String? ?? '--:--';

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
            'Trip Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildTimelineItem(
                  context,
                  'Current Stop',
                  currentStop,
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: AppTheme.successAction,
                    size: 20,
                  ),
                  true,
                ),
              ),
              Container(
                width: 8.w,
                height: 2,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildTimelineItem(
                  context,
                  'Next Stop',
                  nextStop,
                  CustomIconWidget(
                    iconName: 'radio_button_unchecked',
                    color: theme.colorScheme.outline,
                    size: 20,
                  ),
                  false,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryBusminder.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  color: AppTheme.primaryBusminder,
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Text(
                  'ETA: $estimatedArrival',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBusminder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    String value,
    Widget icon,
    bool isActive,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}

