import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChildStatusCard extends StatelessWidget {
  final Map<String, dynamic> childData;
  final VoidCallback? onTap;

  const ChildStatusCard({
    Key? key,
    required this.childData,
    this.onTap,
  }) : super(key: key);

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  bool _isTrackable(String status) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus != 'at_home' &&
           lowerStatus != 'at_school' &&
           lowerStatus != 'no record today';
  }

  @override
  Widget build(BuildContext context) {
    final String status = childData['status'] ?? 'No record today';
    final String name = childData['name'] ?? 'Child Name';
    final String grade = childData['grade'] ?? 'N/A';
    final bool isTrackable = _isTrackable(status);

    return GestureDetector(
      onTap: isTrackable ? onTap : null,
      child: Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _getStatusColor(status),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          // Child info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Grade $grade',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 1.h),
                // Status row
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 4.w,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Status: ',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _getStatusText(status),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_bus':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'at_school':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'at_home':
        return const Color(0xFF34C759);
      case 'waiting':
        return const Color(0xFFFF9500);
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'on_bus':
        return 'On bus';
      case 'at_school':
        return 'At school';
      case 'at_home':
        return 'At home';
      case 'waiting':
        return 'Waiting';
      case 'no record today':
        return 'No record today';
      default:
        return 'Unknown';
    }
  }
}

