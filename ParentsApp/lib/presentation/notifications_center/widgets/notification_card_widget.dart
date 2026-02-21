import 'package:flutter/material.dart';

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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get unique styling for this notification type
    final notificationStyle = _getNotificationStyle(type, context);
    final Color typeColor = notificationStyle['color'];

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: isCritical
              ? colorScheme.error.withValues(alpha: 0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isRead
                ? colorScheme.outline
                : typeColor.withValues(alpha: 0.3),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 2,
            ),
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.09),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: notificationStyle['icon'],
                            color: typeColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + timestamp row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      color: isCritical
                                          ? colorScheme.error
                                          : colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimestamp(notification['timestamp']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Message body
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              maxLines:
                                  notification['expanded'] == true ? 10 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Expanded details
                            if (notification['expanded'] == true) ...[
                              if (hasExtraDetails) ...[
                                const SizedBox(height: 10),
                                Text(
                                  fullMessage!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              // Action buttons
                              Row(
                                children: [
                                  if (type == 'bus_approaching' ||
                                      type == 'pickup_confirmed') ...[
                                    _buildActionButton(
                                      context,
                                      icon: 'map',
                                      label: 'View on Map',
                                      color: colorScheme.primary,
                                      onTap: onViewOnMap,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _buildActionButton(
                                    context,
                                    icon: 'phone',
                                    label: 'Call Driver',
                                    color: colorScheme.secondary,
                                    onTap: onContactSchool,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Unread badge
                  if (!isRead) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
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

  Widget _buildActionButton(
    BuildContext context, {
    required String icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
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
          'color': const Color(0xFF2B5CE6),
          'icon': 'directions_bus',
        };
      case 'pickup_confirmed':
        return {
          'color': const Color(0xFF34C759),
          'icon': 'check_circle',
        };
      case 'dropoff_complete':
        return {
          'color': const Color(0xFF22C55E),
          'icon': 'verified',
        };
      case 'route_change':
        return {
          'color': const Color(0xFFFF9500),
          'icon': 'alt_route',
        };
      case 'emergency':
        return {
          'color': const Color(0xFFFF3B30),
          'icon': 'warning',
        };
      case 'major_delay':
        return {
          'color': const Color(0xFFEF4444),
          'icon': 'schedule',
        };
      case 'trip_started':
        return {
          'color': const Color(0xFF2B5CE6),
          'icon': 'directions_bus',
        };
      case 'trip_ended':
      case 'trip_completed':
      case 'student_reached_safely':
      case 'reached_safely':
        return {
          'color': const Color(0xFF34C759),
          'icon': 'check_circle',
        };
      default:
        return {
          'color': Theme.of(context).colorScheme.onSurfaceVariant,
          'icon': 'notifications',
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
