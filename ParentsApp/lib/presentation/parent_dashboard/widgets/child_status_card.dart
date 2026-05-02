import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String status = (childData['status'] ?? '').toLowerCase();
    final String name = childData['name'] ?? 'Child';
    final String? grade = childData['grade'];
    final String? routeName = childData['routeName'];

    final bool isOnBus = status == 'on_bus' || status == 'on-bus' ||
        status == 'picked_up' || status == 'picked-up';
    final bool isAtSchool = status == 'at_school' || status == 'at-school';

    final _StatusConfig statusConfig = _resolveStatus(status, isDark);
    final _ActionConfig actionConfig = _resolveAction(isOnBus, isAtSchool, colorScheme, isDark);

    final String gradeRoute = [
      if (grade != null && grade.isNotEmpty) grade,
      if (routeName != null && routeName.isNotEmpty) routeName,
    ].join(' • ');

    final String initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: initial avatar + name/grade + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initial avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + grade/route
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (gradeRoute.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          gradeRoute,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(config: statusConfig),
              ],
            ),

            const SizedBox(height: 16),

            // Action button — full width
            ElevatedButton.icon(
              onPressed: onTrackLive,
              icon: Icon(actionConfig.icon, size: 16,
                  color: actionConfig.foregroundColor),
              label: Text(
                actionConfig.label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: actionConfig.foregroundColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: actionConfig.backgroundColor,
                foregroundColor: actionConfig.foregroundColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _resolveStatus(String status, bool isDark) {
    switch (status) {
      case 'on_bus':
      case 'on-bus':
      case 'picked_up':
      case 'picked-up':
        return _StatusConfig(
          label: status.contains('picked') ? 'PICKED UP' : 'ON BUS',
          backgroundColor: const Color(0xFF007D55),
          textColor: const Color(0xFFBDFFDB),
          dotColor: const Color(0xFFBDFFDB),
        );
      case 'at_school':
      case 'at-school':
        return _StatusConfig(
          label: 'AT SCHOOL',
          backgroundColor: const Color(0xFF004AC6),
          textColor: Colors.white,
          dotColor: Colors.white,
        );
      case 'waiting':
        return _StatusConfig(
          label: 'WAITING',
          backgroundColor: const Color(0xFFFFDAD6),
          textColor: const Color(0xFF93000A),
          dotColor: const Color(0xFF93000A),
        );
      default:
        // AT HOME, dropped off, no record — neutral badge
        return _StatusConfig(
          label: 'AT HOME',
          backgroundColor: isDark
              ? AppTheme.dividerDark
              : const Color(0xFFDCE9FF),
          textColor: isDark
              ? AppTheme.textSecondaryDark
              : const Color(0xFF434655),
          dotColor: null,
        );
    }
  }

  _ActionConfig _resolveAction(
      bool isOnBus, bool isAtSchool, ColorScheme colorScheme, bool isDark) {
    if (isOnBus || isAtSchool) {
      return _ActionConfig(
        label: 'Track Live',
        icon: Icons.location_on_rounded,
        backgroundColor: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
        foregroundColor: colorScheme.primary,
      );
    }
    return _ActionConfig(
      label: 'View History',
      icon: Icons.history_rounded,
      backgroundColor: isDark
          ? AppTheme.dividerDark.withValues(alpha: 0.5)
          : const Color(0xFFEFF4FF),
      foregroundColor: colorScheme.onSurfaceVariant,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusConfig config;
  const _StatusBadge({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: config.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            config.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: config.textColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? dotColor;
  const _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.dotColor,
  });
}

class _ActionConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  const _ActionConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}
