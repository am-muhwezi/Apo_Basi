import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
// ignore_for_file: unnecessary_import

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    final cardBg = isRead
        ? (isDark
            ? AppTheme.cardDark.withValues(alpha: 0.6)
            : const Color(0xFFF8FAFF))
        : (isDark ? AppTheme.cardDark : Colors.white);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: typeColor
                              .withValues(alpha: isDark ? 0.2 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(typeIcon, color: typeColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + "New" badge row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] ?? '',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700,
                                      color: isCritical
                                          ? colorScheme.error
                                          : colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: typeColor,
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      'New',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Timestamp
                            Text(
                              _formatTimestamp(notification['timestamp']),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Message body
                            Text(
                              message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isRead
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
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
                                  fullMessage,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (type == 'bus_approaching' ||
                                      type == 'pickup_confirmed') ...[
                                    _buildActionButton(
                                      context,
                                      icon: Icons.map_rounded,
                                      label: 'View on Map',
                                      color: colorScheme.primary,
                                      onTap: onViewOnMap,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _buildActionButton(
                                    context,
                                    icon: Icons.phone_rounded,
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
    required IconData icon,
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'pickup_confirmed':
      case 'dropoff_complete':
      case 'trip_ended':
      case 'trip_completed':
      case 'student_reached_safely':
      case 'reached_safely':
        return const Color(0xFF007D55);
      case 'bus_approaching':
      case 'trip_started':
        return const Color(0xFF004AC6);
      case 'route_change':
        return const Color(0xFFA16500);
      case 'emergency':
      case 'major_delay':
        return const Color(0xFFBA1A1A);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'pickup_confirmed':
        return Icons.check_circle_rounded;
      case 'dropoff_complete':
      case 'trip_ended':
      case 'trip_completed':
      case 'student_reached_safely':
      case 'reached_safely':
        return Icons.verified_rounded;
      case 'bus_approaching':
      case 'trip_started':
        return Icons.directions_bus_rounded;
      case 'route_change':
        return Icons.alt_route_rounded;
      case 'emergency':
        return Icons.warning_rounded;
      case 'major_delay':
        return Icons.schedule_rounded;
      default:
        return Icons.notifications_rounded;
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
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
