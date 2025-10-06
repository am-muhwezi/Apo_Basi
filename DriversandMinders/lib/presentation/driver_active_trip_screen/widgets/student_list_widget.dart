import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Student list widget with pickup status toggles
class StudentListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final Function(int, bool) onPickupStatusChanged;

  const StudentListWidget({
    super.key,
    required this.students,
    required this.onPickupStatusChanged,
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
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.students.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
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
    final specialNotes = student["specialNotes"] as String?;
    final parentContact = student["parentContact"] as String?;

    return Dismissible(
      key: Key('student_$index'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (!isPickedUp) {
          HapticFeedback.mediumImpact();
          widget.onPickupStatusChanged(index, true);
          return false; // Don't actually dismiss
        }
        return false;
      },
      background: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.successAction,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.textOnPrimary,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              'Mark Picked Up',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isPickedUp
              ? AppTheme.successAction.withValues(alpha: 0.1)
              : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPickedUp
                ? AppTheme.successAction.withValues(alpha: 0.3)
                : AppTheme.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              offset: Offset(0, 1),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Student avatar
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isPickedUp
                    ? AppTheme.successAction
                    : AppTheme.primaryDriver,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          studentName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPickedUp)
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.successAction,
                          size: 20,
                        ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Grade $studentGrade • $stopName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (specialNotes != null && specialNotes.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.warningState.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        specialNotes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningState,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                  if (parentContact != null && parentContact.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      'Contact: $parentContact',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Pickup toggle
            Switch(
              value: isPickedUp,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                widget.onPickupStatusChanged(index, value);
              },
              activeColor: AppTheme.successAction,
              inactiveThumbColor: AppTheme.textSecondary,
              inactiveTrackColor: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

