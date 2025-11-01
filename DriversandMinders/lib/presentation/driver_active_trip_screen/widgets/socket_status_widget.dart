import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget to display Socket.IO connection status
///
/// Shows:
/// - Green indicator when connected to real-time server
/// - Red indicator when disconnected
/// - Amber indicator when connecting
class SocketStatusWidget extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onTap;

  const SocketStatusWidget({
    super.key,
    required this.isConnected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isConnected
              ? AppTheme.successAction.withValues(alpha: 0.1)
              : AppTheme.criticalAlert.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConnected ? AppTheme.successAction : AppTheme.criticalAlert,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Connection status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isConnected ? AppTheme.successAction : AppTheme.criticalAlert,
                shape: BoxShape.circle,
                boxShadow: isConnected
                    ? [
                        BoxShadow(
                          color: AppTheme.successAction.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),

            SizedBox(width: 3.w),

            // Status icon
            CustomIconWidget(
              iconName: isConnected ? 'wifi' : 'wifi_off',
              color: isConnected ? AppTheme.successAction : AppTheme.criticalAlert,
              size: 20,
            ),

            SizedBox(width: 2.w),

            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Live Tracking Active' : 'Live Tracking Offline',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isConnected ? AppTheme.successAction : AppTheme.criticalAlert,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    isConnected
                        ? 'Real-time location sharing with parents'
                        : 'Unable to share location in real-time',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Info icon
            if (onTap != null)
              CustomIconWidget(
                iconName: 'info',
                color: AppTheme.textSecondary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
