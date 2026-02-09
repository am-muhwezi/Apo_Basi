import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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

    final Color statusColor = _getStatusColor(context, status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    grade,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  // Status chip with label inside
                  Semantics(
                    label: 'Status',
                    value: _getStatusText(status),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.6.h),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 1.5.w,
                            height: 1.5.w,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 1.5.w),
                          Text(
                            'Status: ${_getStatusText(status)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              size: 5.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String? status) {
    if (status == null || status.trim().isEmpty) {
      return const Color(0xFF34C759); // Green for 'At home'
    }

    switch (status.toLowerCase()) {
      case 'on_bus':
      case 'on-bus':
        return const Color(0xFFFF9500); // Orange - child is traveling
      case 'at_school':
      case 'at-school':
        return const Color(0xFF007AFF); // Blue - child at school
      case 'at_home':
      case 'at-home':
      case 'home':
        return const Color(0xFF34C759); // Green - child at home
      case 'picked-up':
      case 'picked_up':
        return const Color(0xFF5856D6); // Purple - child picked up
      case 'dropped-off':
      case 'dropped_off':
        return const Color(0xFF34C759); // Green - same as home
      case 'waiting':
        return const Color(0xFFFF3B30); // Red - waiting/alert
      default:
        return const Color(0xFF34C759); // Default to green for 'At home'
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
        return 'At home'; // Default to 'At home' instead of 'Unknown'
    }
  }
}
