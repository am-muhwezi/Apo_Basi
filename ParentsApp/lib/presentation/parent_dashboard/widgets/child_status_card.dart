import 'package:flutter/material.dart';

class ChildStatusCard extends StatelessWidget {
  final Map<String, dynamic> childData;
  final VoidCallback? onTrackLive;

  const ChildStatusCard({
    Key? key,
    required this.childData,
    this.onTrackLive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final String status = childData['status'] ?? 'No record today';
    final String name = childData['name'] ?? 'Child Name';
    final String? busNumber = childData['busNumber'];
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline,
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
      child: Column(
        children: [
          // Top row: avatar + name/bus
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : const Color(0xFFE9E7F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitial(name),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and bus
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (busNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Bus: $busNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bottom row: status pill + Track Live button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Track Live button
              SizedBox(
                width: 101,
                height: 40,
                child: ElevatedButton(
                  onPressed: onTrackLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Track Live',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'C';
    return trimmed[0].toUpperCase();
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.trim().isEmpty) {
      return const Color(0xFF22CCB2);
    }

    switch (status.toLowerCase()) {
      case 'on_bus':
      case 'on-bus':
        return const Color(0xFFFF9500);
      case 'at_school':
      case 'at-school':
        return const Color(0xFF007AFF);
      case 'at_home':
      case 'at-home':
      case 'home':
        return const Color(0xFF22CCB2);
      case 'picked-up':
      case 'picked_up':
        return const Color(0xFF5856D6);
      case 'dropped-off':
      case 'dropped_off':
        return const Color(0xFF22CCB2);
      case 'waiting':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF22CCB2);
    }
  }

  String _getStatusText(String? status) {
    if (status == null || status.trim().isEmpty) {
      return 'At home';
    }

    switch (status.toLowerCase()) {
      case 'on_bus':
      case 'on-bus':
        return 'On bus';
      case 'at_school':
      case 'at-school':
        return 'At school';
      case 'at_home':
      case 'at-home':
      case 'home':
        return 'At home';
      case 'waiting':
        return 'Waiting';
      case 'picked-up':
      case 'picked_up':
        return 'Picked up';
      case 'dropped-off':
      case 'dropped_off':
        return 'Dropped off';
      case 'no record today':
        return 'No record today';
      default:
        return 'At home';
    }
  }
}
