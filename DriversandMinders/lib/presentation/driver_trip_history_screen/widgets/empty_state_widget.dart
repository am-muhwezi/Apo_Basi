import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool showFiltersButton;

  const EmptyStateWidget({
    super.key,
    this.title = 'No trips found',
    this.subtitle = 'Try adjusting your search or filter criteria',
    this.actionText,
    this.onActionPressed,
    this.showFiltersButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 2.0,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'history',
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 60,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.h),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // Action buttons
            if (showFiltersButton || actionText != null)
              Column(
                children: [
                  if (showFiltersButton)
                    OutlinedButton.icon(
                      onPressed: onActionPressed,
                      icon: CustomIconWidget(
                        iconName: 'filter_list',
                        color: AppTheme.primaryDriver,
                        size: 20,
                      ),
                      label: Text(
                        'Adjust Filters',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryDriver,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                        side: BorderSide(color: AppTheme.primaryDriver),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  if (actionText != null && showFiltersButton)
                    SizedBox(height: 2.h),
                  if (actionText != null)
                    ElevatedButton(
                      onPressed: onActionPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDriver,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        actionText!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

