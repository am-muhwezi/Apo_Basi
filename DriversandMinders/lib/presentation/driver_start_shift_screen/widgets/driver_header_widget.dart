import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DriverHeaderWidget extends StatelessWidget {
  final String driverName;
  final String driverId;
  final VoidCallback onLogout;
  final VoidCallback? onMenuTap;

  const DriverHeaderWidget({
    super.key,
    required this.driverName,
    required this.driverId,
    required this.onLogout,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryDriver.withValues(alpha: 0.05),
            AppTheme.backgroundPrimary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu button (hamburger)
          InkWell(
            onTap: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryDriver.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryDriver.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'menu',
                color: AppTheme.primaryDriver,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: AppTheme.lightDriverTheme.textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Driver ID: $driverId',
                  style:
                      AppTheme.lightDriverTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: AppTheme.criticalAlert.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.criticalAlert.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'logout',
                color: AppTheme.criticalAlert,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

