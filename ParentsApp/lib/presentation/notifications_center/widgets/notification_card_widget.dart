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

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isCritical
            ? AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _getNotificationColor(type),
            width: isRead ? 2 : 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color:
                            _getNotificationColor(type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: _getNotificationIcon(type),
                        color: _getNotificationColor(type),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
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
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                    color: isCritical
                                        ? AppTheme.lightTheme.colorScheme.error
                                        : AppTheme
                                            .lightTheme.colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatTimestamp(notification['timestamp']),
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            message,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (notification['expanded'] == true) ...[
                            if (hasExtraDetails) ...[
                              SizedBox(height: 2.h),
                              Text(
                                fullMessage!,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
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
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'View on Map',
                                      style: AppTheme
                                          .lightTheme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                ],
                                TextButton.icon(
                                  onPressed: onContactSchool,
                                  icon: CustomIconWidget(
                                    iconName: 'phone',
                                    color: AppTheme
                                        .lightTheme.colorScheme.secondary,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Call Driver',
                                    style: AppTheme
                                        .lightTheme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.secondary,
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
                  SizedBox(height: 1.h),
                  Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'bus_approaching':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'pickup_confirmed':
      case 'dropoff_complete':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'route_change':
        return const Color(0xFFFF9500);
      case 'emergency':
      case 'major_delay':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'bus_approaching':
        return 'directions_bus';
      case 'pickup_confirmed':
      case 'dropoff_complete':
        return 'check_circle';
      case 'route_change':
        return 'alt_route';
      case 'emergency':
        return 'warning';
      case 'major_delay':
        return 'schedule';
      default:
        return 'notifications';
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
