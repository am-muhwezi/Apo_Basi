import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GpsStatusWidget extends StatelessWidget {
  final bool isGpsConnected;
  final String currentTime;

  const GpsStatusWidget({
    super.key,
    required this.isGpsConnected,
    required this.currentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightDriverTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightDriverTheme.colorScheme.outline
                .withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: isGpsConnected ? 'gps_fixed' : 'gps_not_fixed',
                color: isGpsConnected
                    ? AppTheme.successAction
                    : AppTheme.warningState,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                isGpsConnected ? 'GPS Connected' : 'GPS Searching...',
                style: AppTheme.lightDriverTheme.textTheme.bodySmall?.copyWith(
                  color: isGpsConnected
                      ? AppTheme.successAction
                      : AppTheme.warningState,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            currentTime,
            style: AppTheme.lightDriverTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

