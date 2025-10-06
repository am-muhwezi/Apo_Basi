import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;
  final DateTime? lastUpdateTime;
  final String connectionQuality;

  const ConnectionStatusWidget({
    Key? key,
    required this.isConnected,
    this.lastUpdateTime,
    required this.connectionQuality,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8.h,
      left: 4.w,
      right: 4.w,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: _getStatusColor().withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConnectionIcon(),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusText(),
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastUpdateTime != null)
                    Text(
                      _getLastUpdateText(),
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
            _buildSignalStrength(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIcon() {
    return Container(
      width: 6.w,
      height: 3.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: isConnected ? 'wifi' : 'wifi_off',
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildSignalStrength() {
    final strength = _getSignalStrength();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 0.5.w,
          height: (index + 1) * 0.5.h,
          margin: EdgeInsets.only(left: 0.5.w),
          decoration: BoxDecoration(
            color: index < strength
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getStatusColor() {
    if (!isConnected) return Colors.red.shade600;

    switch (connectionQuality.toLowerCase()) {
      case 'excellent':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'good':
        return Colors.green.shade600;
      case 'fair':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'poor':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText() {
    if (!isConnected) return 'Offline Mode';
    return 'Live Tracking • $connectionQuality';
  }

  String _getLastUpdateText() {
    if (lastUpdateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastUpdateTime!);

    if (difference.inSeconds < 60) {
      return 'Updated ${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes}m ago';
    } else {
      return 'Updated ${difference.inHours}h ago';
    }
  }

  int _getSignalStrength() {
    if (!isConnected) return 0;

    switch (connectionQuality.toLowerCase()) {
      case 'excellent':
        return 4;
      case 'good':
        return 3;
      case 'fair':
        return 2;
      case 'poor':
        return 1;
      default:
        return 0;
    }
  }
}
