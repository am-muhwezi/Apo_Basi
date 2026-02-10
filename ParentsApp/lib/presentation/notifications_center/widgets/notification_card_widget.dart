import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onContactSchool;
  final VoidCallback? onViewOnMap;

  const NotificationCardWidget({
    Key? key,
    required this.notification,
    this.onTap,
    this.onMarkRead,
    this.onShare,
    this.onDelete,
    this.onContactSchool,
    this.onViewOnMap,
  }) : super(key: key);

  // Add unique key based on notification ID to prevent unnecessary rebuilds
  @override
  Key? get key => ValueKey(notification['id']);

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'] ?? false;
    final String type = notification['type'] ?? '';
    final bool isCritical = type == 'emergency' || type == 'major_delay';
    final String message = notification['message'] ?? '';
    final String? fullMessage = notification['fullMessage'];
    final bool hasExtraDetails = fullMessage != null &&
        fullMessage.trim().isNotEmpty &&
        fullMessage.trim() != message.trim();

    // Cache theme to avoid repeated lookups
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Get unique styling for this notification type
    final notificationStyle = _getNotificationStyle(type, context);

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
        decoration: BoxDecoration(
          color: isCritical
              ? colorScheme.error.withValues(alpha: 0.05)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.transparent
                : notificationStyle['color'].withValues(alpha: 0.2),
            width: isRead ? 0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: notificationStyle['color']
                  .withValues(alpha: isRead ? 0.02 : 0.06),
              blurRadius: isRead ? 3 : 8,
              offset: Offset(0, isRead ? 1 : 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.8.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(1.8.w),
                        decoration: BoxDecoration(
                          color: notificationStyle['color']
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: notificationStyle['color']
                                .withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: notificationStyle['icon'],
                          color: notificationStyle['color'],
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 2.5.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] ?? '',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700,
                                      fontSize: 13.5.sp,
                                      letterSpacing: -0.2,
                                      color: isCritical
                                          ? colorScheme.error
                                          : colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(notification['timestamp']),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 0.8.h),
                            Text(
                              message,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: 12.sp,
                                height: 1.3,
                                letterSpacing: 0,
                              ),
                              maxLines:
                                  notification['expanded'] == true ? 10 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (notification['expanded'] == true) ...[
                              if (hasExtraDetails) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  fullMessage!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                              ],
                              Row(
                                children: [
                                  if (type == 'bus_approaching' ||
                                      type == 'pickup_confirmed') ...[
                                    TextButton.icon(
                                      onPressed: onViewOnMap,
                                      icon: CustomIconWidget(
                                        iconName: 'map',
                                        color: colorScheme.primary,
                                        size: 16,
                                      ),
                                      label: Text(
                                        'View on Map',
                                        style: textTheme.labelMedium?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                  ],
                                  TextButton.icon(
                                    onPressed: onContactSchool,
                                    icon: CustomIconWidget(
                                      iconName: 'phone',
                                      color: colorScheme.secondary,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Call Driver',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isRead) ...[
                    SizedBox(height: 0.8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color:
                            notificationStyle['color'].withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 1.2.w,
                            height: 1.2.w,
                            decoration: BoxDecoration(
                              color: notificationStyle['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'New',
                            style: textTheme.labelSmall?.copyWith(
                              color: notificationStyle['color'],
                              fontWeight: FontWeight.w600,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Get unique styling for each notification type
  Map<String, dynamic> _getNotificationStyle(
      String type, BuildContext context) {
    switch (type) {
      case 'bus_approaching':
        return {
          'color': const Color(0xFF2B5CE6), // Blue
          'icon': 'directions_bus',
          'gradient': [const Color(0xFF2B5CE6), const Color(0xFF1E3A8A)],
        };
      case 'pickup_confirmed':
        return {
          'color': const Color(0xFF34C759), // Green
          'icon': 'check_circle',
          'gradient': [const Color(0xFF34C759), const Color(0xFF10B981)],
        };
      case 'dropoff_complete':
        return {
          'color': const Color(0xFF22C55E), // Lighter green
          'icon': 'verified',
          'gradient': [const Color(0xFF22C55E), const Color(0xFF16A34A)],
        };
      case 'route_change':
        return {
          'color': const Color(0xFFFF9500), // Orange
          'icon': 'alt_route',
          'gradient': [const Color(0xFFFF9500), const Color(0xFFF97316)],
        };
      case 'emergency':
        return {
          'color': const Color(0xFFFF3B30), // Red
          'icon': 'warning',
          'gradient': [const Color(0xFFFF3B30), const Color(0xFFDC2626)],
        };
      case 'major_delay':
        return {
          'color': const Color(0xFFEF4444), // Red
          'icon': 'schedule',
          'gradient': [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        };
      case 'trip_started':
        return {
          'color': const Color(0xFF2B5CE6), // Blue (matching bus_approaching)
          'icon': 'directions_bus',
          'gradient': [const Color(0xFF2B5CE6), const Color(0xFF1E3A8A)],
        };
      case 'trip_ended':
      case 'trip_completed':
      case 'student_reached_safely':
      case 'reached_safely':
        return {
          'color': const Color(0xFF34C759), // Green (matching pickup_confirmed)
          'icon': 'check_circle',
          'gradient': [const Color(0xFF34C759), const Color(0xFF10B981)],
        };
      default:
        return {
          'color': Theme.of(context).colorScheme.onSurfaceVariant,
          'icon': 'notifications',
          'gradient': [
            Theme.of(context).colorScheme.onSurfaceVariant,
            Theme.of(context).colorScheme.onSurfaceVariant
          ],
        };
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
