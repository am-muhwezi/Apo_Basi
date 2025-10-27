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

  @override
  Widget build(BuildContext context) {
    final String status = childData['status'] ?? 'No record today';
    final String name = childData['name'] ?? 'Child Name';
    final String grade = childData['grade'] ?? 'N/A';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50), // Green
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4CAF50), // Green
                    fontSize: 16.sp,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    grade,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  // Status chip with yellow background
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDD835), // Bright yellow
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 1.5.w,
                          height: 1.5.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50), // Green dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.5.w),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 5.w,
              color: Colors.white.withValues(alpha: 0.7),
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

