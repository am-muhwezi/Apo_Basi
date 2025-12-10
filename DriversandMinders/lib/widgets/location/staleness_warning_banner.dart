import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../config/location_config.dart';

/// Staleness Warning Banner
///
/// Shows a warning banner when location data is stale or offline.
/// Automatically determines warning level based on age of data.
class StalenessWarningBanner extends StatelessWidget {
  final DateTime? lastUpdateTime;
  final VoidCallback? onRetry;
  final bool showRetryButton;

  const StalenessWarningBanner({
    Key? key,
    this.lastUpdateTime,
    this.onRetry,
    this.showRetryButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lastUpdateTime == null) {
      return _buildBanner(
        context: context,
        severity: WarningSeverity.error,
        message: 'No location data available',
        icon: Icons.error_outline,
      );
    }

    final age = DateTime.now().difference(lastUpdateTime!);

    // Fresh data - no warning
    if (age < LocationConfig.staleThreshold) {
      return const SizedBox.shrink();
    }

    // Stale data - yellow warning
    if (age < LocationConfig.offlineThreshold) {
      return _buildBanner(
        context: context,
        severity: WarningSeverity.warning,
        message: 'Location data is ${_formatAge(age)} old',
        icon: Icons.warning_amber,
      );
    }

    // Offline - red error
    return _buildBanner(
      context: context,
      severity: WarningSeverity.error,
      message: 'Bus appears offline (last update ${_formatAge(age)} ago)',
      icon: Icons.signal_wifi_off,
    );
  }

  Widget _buildBanner({
    required BuildContext context,
    required WarningSeverity severity,
    required String message,
    required IconData icon,
  }) {
    final colors = _getSeverityColors(severity);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colors.icon,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (severity == WarningSeverity.error)
                  Text(
                    'The driver may have lost connection',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.text.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (showRetryButton && onRetry != null) ...[
            SizedBox(width: 2.w),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colors.icon,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  SeverityColors _getSeverityColors(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.warning:
        return SeverityColors(
          background: Colors.amber.shade50,
          border: Colors.amber.shade200,
          icon: Colors.amber.shade700,
          text: Colors.amber.shade900,
        );
      case WarningSeverity.error:
        return SeverityColors(
          background: Colors.red.shade50,
          border: Colors.red.shade200,
          icon: Colors.red.shade700,
          text: Colors.red.shade900,
        );
    }
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 2) {
      return '${age.inSeconds}s';
    } else if (age.inMinutes < 60) {
      return '${age.inMinutes}m';
    } else {
      return '${age.inHours}h';
    }
  }
}

enum WarningSeverity { warning, error }

class SeverityColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;

  SeverityColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });
}
