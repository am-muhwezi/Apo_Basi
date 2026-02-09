import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ConnectionStatusBar extends StatelessWidget {
  final bool isConnected;
  final String lastUpdated;

  const ConnectionStatusBar({
    Key? key,
    required this.isConnected,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isConnected
            ? const Color(0xFF34C759).withValues(alpha: 0.1)
            : const Color(0xFFFF9500).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected
                  ? const Color(0xFF34C759)
                  : const Color(0xFFFF9500),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              isConnected
                  ? 'Live tracking active'
                  : 'Last updated: $lastUpdated',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isConnected
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (!isConnected)
            GestureDetector(
              onTap: () {
                // Refresh connection
              },
              child: CustomIconWidget(
                iconName: 'refresh',
                color: const Color(0xFFFF9500),
                size: 4.w,
              ),
            ),
        ],
      ),
    );
  }
}
