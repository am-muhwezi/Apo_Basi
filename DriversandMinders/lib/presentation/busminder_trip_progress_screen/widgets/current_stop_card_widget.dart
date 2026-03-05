import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CurrentStopCardWidget extends StatefulWidget {
  final Map<String, dynamic> stopData;
  final Function(String studentId, bool isBoarding) onAttendanceToggle;

  const CurrentStopCardWidget({
    super.key,
    required this.stopData,
    required this.onAttendanceToggle,
  });

  @override
  State<CurrentStopCardWidget> createState() => _CurrentStopCardWidgetState();
}

class _CurrentStopCardWidgetState extends State<CurrentStopCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stopName = widget.stopData['name'] as String? ?? 'Unknown Stop';
    final students =
        (widget.stopData['students'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    final instructions = widget.stopData['instructions'] as String? ?? '';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'location_on',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stop',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        stopName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${students.length} students',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (instructions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: Theme.of(context).colorScheme.tertiary,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      instructions,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students at this stop',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                students.isEmpty
                    ? _buildEmptyState(context)
                    : Column(
                        children: students
                            .map((student) =>
                                _buildStudentItem(context, student))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'school',
            color: theme.colorScheme.outline,
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No students at this stop',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(BuildContext context, Map<String, dynamic> student) {
    final theme = Theme.of(context);
    final name = student['name'] as String? ?? 'Unknown Student';
    final id = student['id'] as String? ?? '';
    final grade = student['grade'] as String? ?? '';
    final isBoarding = student['isBoarding'] as bool? ?? true;
    final status = student['status'] as String? ?? 'waiting';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'boarded':
        statusColor = Theme.of(context).colorScheme.secondary;
        statusIcon = Icons.check_circle;
        statusText = 'Boarded';
        break;
      case 'absent':
        statusColor = Theme.of(context).colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      default:
        statusColor = Theme.of(context).colorScheme.tertiary;
        statusIcon = Icons.schedule;
        statusText = 'Waiting';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: CustomIconWidget(
              iconName: 'person',
              color: statusColor,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (grade.isNotEmpty)
                  Text(
                    'Grade $grade',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: statusIcon.codePoint.toString(),
                      color: statusColor,
                      size: 14,
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
              SizedBox(height: 1.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    context,
                    'Board',
                    Icons.login,
                    Theme.of(context).colorScheme.secondary,
                    status != 'boarded',
                    () {
                      HapticFeedback.lightImpact();
                      widget.onAttendanceToggle(id, true);
                    },
                  ),
                  SizedBox(width: 2.w),
                  _buildActionButton(
                    context,
                    'Absent',
                    Icons.close,
                    Theme.of(context).colorScheme.error,
                    status != 'absent',
                    () {
                      HapticFeedback.lightImpact();
                      widget.onAttendanceToggle(id, false);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.1)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon.codePoint.toString(),
              color: enabled ? color : theme.colorScheme.outline,
              size: 14,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: enabled ? color : theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

