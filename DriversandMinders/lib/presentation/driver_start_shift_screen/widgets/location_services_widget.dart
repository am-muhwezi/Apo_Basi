import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LocationServicesWidget extends StatelessWidget {
  final bool isLocationEnabled;
  final String accuracyText;
  final VoidCallback onToggle;

  const LocationServicesWidget({
    super.key,
    required this.isLocationEnabled,
    required this.accuracyText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightDriverTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocationEnabled
              ? AppTheme.successAction.withValues(alpha: 0.3)
              : AppTheme.warningState.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Services',
                      style: AppTheme.lightDriverTheme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Enable GPS tracking for route monitoring',
                      style: AppTheme.lightDriverTheme.textTheme.bodySmall
                          ?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isLocationEnabled,
                onChanged: (_) => onToggle(),
                activeColor: AppTheme.successAction,
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor:
                    AppTheme.textSecondary.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (isLocationEnabled) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.successAction.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'gps_fixed',
                    color: AppTheme.successAction,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'GPS Accuracy: $accuracyText',
                    style:
                        AppTheme.lightDriverTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.successAction,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your location will be shared with the school administration for safety and route monitoring purposes.',
              style: AppTheme.lightDriverTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

