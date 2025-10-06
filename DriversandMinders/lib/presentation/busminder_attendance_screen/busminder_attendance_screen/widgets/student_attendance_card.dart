import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Individual student attendance card widget with pickup/drop-off toggles
class StudentAttendanceCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final Function(String studentId, String status) onStatusChanged;
  final Function(String studentId) onSwipeRight;
  final Function(String studentId) onSwipeLeft;
  final Function(String studentId) onLongPress;

  const StudentAttendanceCard({
    super.key,
    required this.student,
    required this.onStatusChanged,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onLongPress,
  });

  @override
  State<StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<StudentAttendanceCard> {
  String _currentStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.student['status'] as String? ?? 'pending';
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'picked_up':
        return AppTheme.successAction;
      case 'dropped_off':
        return AppTheme.warningState;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case 'picked_up':
        return 'Picked Up';
      case 'dropped_off':
        return 'Dropped Off';
      default:
        return 'Pending';
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case 'picked_up':
        return Icons.check_circle;
      case 'dropped_off':
        return Icons.home_filled;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  void _handleStatusToggle() {
    HapticFeedback.selectionClick();
    String newStatus;

    switch (_currentStatus) {
      case 'pending':
        newStatus = 'picked_up';
        break;
      case 'picked_up':
        newStatus = 'dropped_off';
        break;
      case 'dropped_off':
        newStatus = 'pending';
        break;
      default:
        newStatus = 'pending';
    }

    setState(() {
      _currentStatus = newStatus;
    });

    widget.onStatusChanged(widget.student['id'].toString(), newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightBusminderTheme;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress(widget.student['id'].toString());
      },
      child: Dismissible(
        key: Key('student_${widget.student['id']}'),
        background: Container(
          margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryBusminder.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'note_add',
                color: AppTheme.primaryBusminder,
                size: 24,
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Add Note',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryBusminder,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: AppTheme.warningState.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'contact_phone',
                color: AppTheme.warningState,
                size: 24,
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Contact',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.warningState,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            widget.onSwipeRight(widget.student['id'].toString());
          } else if (direction == DismissDirection.endToStart) {
            widget.onSwipeLeft(widget.student['id'].toString());
          }
          return false; // Don't actually dismiss the card
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                // Student Photo
                Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.backgroundSecondary,
                    border: Border.all(
                      color: _getStatusColor(),
                      width: 2.0,
                    ),
                  ),
                  child: widget.student['photo'] != null
                      ? ClipOval(
                          child: CustomImageWidget(
                            imageUrl: widget.student['photo'] as String,
                            width: 15.w,
                            height: 15.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: CustomIconWidget(
                            iconName: 'person',
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                ),

                SizedBox(width: 4.w),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student['name'] as String? ?? 'Unknown Student',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 0.5.h),

                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBusminder
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              'Grade ${widget.student['grade'] ?? 'N/A'}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.primaryBusminder,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          if (widget.student['hasSpecialNeeds'] == true)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warningState
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'medical_services',
                                    color: AppTheme.warningState,
                                    size: 12,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Special',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.warningState,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 1.h),

                      // Status Display
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: _getStatusIcon().codePoint.toString(),
                            color: _getStatusColor(),
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _getStatusText(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Toggle Button
                GestureDetector(
                  onTap: _handleStatusToggle,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: _getStatusIcon().codePoint.toString(),
                        color: _getStatusColor(),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
