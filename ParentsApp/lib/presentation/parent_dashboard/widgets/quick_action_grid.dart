import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionGrid extends StatelessWidget {
  final VoidCallback onLiveMapTap;
  final VoidCallback onTodaysRouteTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onEmergencyContactTap;

  const QuickActionGrid({
    Key? key,
    required this.onLiveMapTap,
    required this.onTodaysRouteTap,
    required this.onNotificationsTap,
    required this.onEmergencyContactTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.2,
        children: [
          _buildActionCard(
            context: context,
            title: 'Live Map',
            subtitle: 'Track bus location',
            iconName: 'location_on',
            color: AppTheme.lightTheme.colorScheme.primary,
            onTap: onLiveMapTap,
          ),
          _buildActionCard(
            context: context,
            title: "Today's Route",
            subtitle: 'View scheduled stops',
            iconName: 'route',
            color: const Color(0xFF34C759),
            onTap: onTodaysRouteTap,
          ),
          _buildActionCard(
            context: context,
            title: 'Notifications',
            subtitle: 'Recent updates',
            iconName: 'notifications',
            color: const Color(0xFFFF9500),
            onTap: onNotificationsTap,
          ),
          _buildActionCard(
            context: context,
            title: 'Emergency',
            subtitle: 'Contact school',
            iconName: 'phone',
            color: const Color(0xFFFF3B30),
            onTap: onEmergencyContactTap,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconName,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow
                  .withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: iconName,
                  color: color,
                  size: 6.w,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Text(
              subtitle,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
