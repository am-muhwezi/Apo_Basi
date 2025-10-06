import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BeginRouteButtonWidget extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  const BeginRouteButtonWidget({
    super.key,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          if (!isEnabled) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.warningState.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningState.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.warningState,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Complete location setup and safety checklist to begin route',
                      style: AppTheme.lightDriverTheme.textTheme.bodySmall
                          ?.copyWith(
                        color: AppTheme.warningState,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          GestureDetector(
            onLongPress: isEnabled
                ? () {
                    HapticFeedback.mediumImpact();
                    onLongPress();
                  }
                : null,
            child: SizedBox(
              width: double.infinity,
              height: 7.h,
              child: ElevatedButton(
                onPressed: isEnabled && !isLoading
                    ? () {
                        HapticFeedback.lightImpact();
                        onPressed();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? AppTheme.primaryDriver
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  foregroundColor: AppTheme.textOnPrimary,
                  elevation: isEnabled ? 4 : 0,
                  shadowColor: AppTheme.shadowLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.textOnPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Starting Route...',
                            style: AppTheme
                                .lightDriverTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.textOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'play_arrow',
                            color: AppTheme.textOnPrimary,
                            size: 28,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Begin Route',
                            style: AppTheme
                                .lightDriverTheme.textTheme.titleLarge
                                ?.copyWith(
                              color: AppTheme.textOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Long press to view route details',
            style: AppTheme.lightDriverTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

