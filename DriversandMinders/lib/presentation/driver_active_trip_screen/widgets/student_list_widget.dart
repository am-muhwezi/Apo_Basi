import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Student list widget - clean read-only view
class StudentListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final Function(int, bool)? onPickupStatusChanged;

  const StudentListWidget({
    super.key,
    required this.students,
    this.onPickupStatusChanged,
  });

  @override
  State<StudentListWidget> createState() => _StudentListWidgetState();
}

class _StudentListWidgetState extends State<StudentListWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Student List',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDriver.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.students.length} Students',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDriver,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student list
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.students.length,
            itemBuilder: (context, index) {
              final student = widget.students[index];
              return _buildStudentCard(context, student, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
      BuildContext context, Map<String, dynamic> student, int index) {
    final theme = Theme.of(context);
    final isPickedUp = student["isPickedUp"] as bool? ?? false;
    final studentName = student["name"] as String? ?? "Unknown Student";
    final studentGrade = student["grade"] as String? ?? "N/A";
    final stopName = student["stopName"] as String? ?? "Unknown Stop";
    final locationStatus = student["locationStatus"] as String? ??
        student["location_status"] as String? ??
        "home";

    // Distinct color coding based on location_status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (locationStatus.toLowerCase()) {
      case 'on-bus':
      case 'on_bus':
        statusColor = Color(0xFF3B82F6); // Blue for on bus
        statusText = 'On Bus';
        statusIcon = Icons.directions_bus;
        break;
      case 'at-school':
      case 'at_school':
        statusColor = Color(0xFF10B981); // Green for at school
        statusText = 'At School';
        statusIcon = Icons.school;
        break;
      case 'home':
        statusColor = Color(0xFF6B7280); // Gray for at home
        statusText = 'At Home';
        statusIcon = Icons.home;
        break;
      case 'picked-up':
      case 'picked_up':
        statusColor = Color(0xFFF59E0B); // Orange/Amber for picked up
        statusText = 'Picked Up';
        statusIcon = Icons.check_circle;
        break;
      case 'dropped-off':
      case 'dropped_off':
        statusColor = Color(0xFF8B5CF6); // Purple for dropped off
        statusText = 'Dropped Off';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Color(0xFF9CA3AF); // Light gray for unknown
        statusText = 'Unknown';
        statusIcon = Icons.help_outline;
    }

    // Use isPickedUp as fallback if locationStatus not available
    if (isPickedUp && locationStatus.toLowerCase() == 'home') {
      statusColor = Color(0xFFF59E0B);
      statusText = 'Picked Up';
      statusIcon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Student avatar with status color
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Student information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Grade $studentGrade • $stopName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
