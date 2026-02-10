import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 70.w,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Container
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'directions_bus',
                color: colorScheme.onPrimary,
                size: 9.w,
              ),
            ),
          ),

          SizedBox(height: 1.5.h),

          // App Name
          Text(
            'ApoBasi',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 0.3.h),

          // App Tagline
          Text(
            'School Bus Tracking & Management',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
