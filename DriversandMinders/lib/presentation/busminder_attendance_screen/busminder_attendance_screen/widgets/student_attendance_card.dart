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
  final String? tripType; // Add trip type to determine which buttons to show

  const StudentAttendanceCard({
    super.key,
    required this.student,
    required this.onStatusChanged,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onLongPress,
    this.tripType,
  });

  @override
  State<StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<StudentAttendanceCard>
    with AutomaticKeepAliveClientMixin {
  String _currentStatus = 'pending';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.student['status'] as String? ?? 'pending';
  }

  @override
  void didUpdateWidget(StudentAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the student ID changed
    if (oldWidget.student['id'] != widget.student['id']) {
      _currentStatus = widget.student['status'] as String? ?? 'pending';
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case 'picked_up':
        return AppTheme.successAction;
      case 'dropped_off':
        return AppTheme.successAction;
      case 'absent':
        return AppTheme.criticalAlert;
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
      case 'absent':
        return 'Absent';
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
      case 'absent':
        return Icons.person_off;
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = AppTheme.lightBusminderTheme;
    final bool isPending = _currentStatus == 'pending';

    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress(widget.student['id'].toString());
        },
        child: Container(
        margin: EdgeInsets.symmetric(vertical: 0.6.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: _currentStatus != 'pending'
                ? _getStatusColor().withValues(alpha: 0.3)
                : AppTheme.borderLight,
            width: _currentStatus != 'pending' ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _currentStatus != 'pending'
                  ? _getStatusColor().withValues(alpha: 0.1)
                  : AppTheme.shadowLight,
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(3.5.w),
              child: Row(
                children: [
                  // Student Photo with Status Indicator
                  Stack(
                    children: [
                      Container(
                        width: 16.w,
                        height: 16.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.backgroundSecondary,
                          border: Border.all(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            width: 2.5,
                          ),
                        ),
                        child: widget.student['photo'] != null
                            ? ClipOval(
                                child: CustomImageWidget(
                                  imageUrl: widget.student['photo'] as String,
                                  width: 16.w,
                                  height: 16.w,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.person,
                                  color: AppTheme.textSecondary,
                                  size: 24,
                                ),
                              ),
                      ),
                      if (_currentStatus != 'pending')
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(1.w),
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getStatusIcon(),
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(width: 4.w),

                  // Student Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.student['name'] as String? ?? 'Unknown Student',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 0.8.h),

                        // Tags Row
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.5.w,
                                vertical: 0.6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBusminder.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                'Grade ${widget.student['grade'] ?? 'N/A'}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primaryBusminder,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (widget.student['hasSpecialNeeds'] == true) ...[
                              SizedBox(width: 2.w),
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.5.w,
                                    vertical: 0.6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningState.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.medical_services,
                                        color: AppTheme.warningState,
                                        size: 11,
                                      ),
                                      SizedBox(width: 1.w),
                                      Flexible(
                                        child: Text(
                                          'Special',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: AppTheme.warningState,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons Section
            if (isPending)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.0),
                    bottomRight: Radius.circular(16.0),
                  ),
                ),
                padding: EdgeInsets.all(3.w),
                child: Row(
                  children: [
                    // Picked Up Button (for pickup) / Dropped Off Button (for dropoff)
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: widget.tripType == 'pickup' ? 'Pick Up' : 'Drop Off',
                        icon: widget.tripType == 'pickup'
                            ? Icons.person_add_alt_1
                            : Icons.home_filled,
                        color: AppTheme.successAction,
                        onTap: () {
                          _handleStatusChange(
                            widget.tripType == 'pickup' ? 'picked_up' : 'dropped_off'
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // Absent Button
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: 'Absent',
                        icon: Icons.person_off,
                        color: AppTheme.criticalAlert,
                        onTap: () {
                          _handleStatusChange('absent');
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // More Options Button
                    _buildIconButton(
                      context,
                      icon: Icons.more_horiz,
                      color: AppTheme.textSecondary,
                      onTap: () {
                        widget.onLongPress(widget.student['id'].toString());
                      },
                    ),
                  ],
                ),
              )
            else
              // Status Display for marked students
              Container(
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.0),
                    bottomRight: Radius.circular(16.0),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          _getStatusText(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _handleStatusChange('pending');
                      },
                      icon: Icon(
                        Icons.undo,
                        size: 16,
                        color: _getStatusColor(),
                      ),
                      label: Text(
                        'Undo',
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.5.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final borderRadius = BorderRadius.circular(12.0);
    return Material(
      color: color,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              SizedBox(width: 2.w),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final borderRadius = BorderRadius.circular(12.0);
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: borderRadius,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _handleStatusChange(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    widget.onStatusChanged(widget.student['id'].toString(), newStatus);
  }
}
