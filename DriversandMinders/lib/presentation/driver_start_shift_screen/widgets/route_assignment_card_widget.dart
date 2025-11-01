import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RouteAssignmentCardWidget extends StatefulWidget {
  final String routeName;
  final String estimatedDuration;
  final int studentCount;
  final List<Map<String, dynamic>> assignedChildren;
  final VoidCallback onTap;
  final String? busNumber;
  final String? routeNameOnly;

  const RouteAssignmentCardWidget({
    super.key,
    required this.routeName,
    required this.estimatedDuration,
    required this.studentCount,
    this.assignedChildren = const [],
    required this.onTap,
    this.busNumber,
    this.routeNameOnly,
  });

  @override
  State<RouteAssignmentCardWidget> createState() => _RouteAssignmentCardWidgetState();
}

class _RouteAssignmentCardWidgetState extends State<RouteAssignmentCardWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppTheme.primaryDriver.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryDriver.withValues(alpha: 0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDriver.withValues(alpha: 0.08),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryDriver,
                          AppTheme.primaryDriver.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDriver.withValues(alpha: 0.3),
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: CustomIconWidget(
                      iconName: 'directions_bus',
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Shift',
                          style: AppTheme.lightDriverTheme.textTheme.titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDriver,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Ready to begin your route',
                          style: AppTheme.lightDriverTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryDriver.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    if (widget.busNumber != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: _buildInfoRow(
                          'Bus Number',
                          widget.busNumber!,
                          Icons.directions_bus,
                        ),
                      ),
                    if (widget.routeNameOnly != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: _buildInfoRow(
                          'Route',
                          widget.routeNameOnly!,
                          Icons.route,
                        ),
                      ),
                    _buildInfoRow(
                      'Route Assignment',
                      widget.routeName,
                      Icons.route,
                    ),
                    SizedBox(height: 2.h),
                    _buildInfoRow(
                      'Estimated Duration',
                      widget.estimatedDuration,
                      Icons.access_time,
                    ),
                    SizedBox(height: 2.h),
                    // Show children list instead of just count
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'people',
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assigned Students',
                                      style: AppTheme.lightDriverTheme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${widget.studentCount} students',
                                      style: AppTheme.lightDriverTheme.textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppTheme.primaryDriver,
                              ),
                            ],
                          ),
                          if (_isExpanded && widget.assignedChildren.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryDriver.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                children: widget.assignedChildren.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final child = entry.value;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: index == widget.assignedChildren.length - 1 ? 0 : 1.5.h),
                                    padding: EdgeInsets.all(3.w),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryDriver.withValues(alpha: 0.04),
                                          AppTheme.primaryDriver.withValues(alpha: 0.02),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.primaryDriver.withValues(alpha: 0.12),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.primaryDriver.withValues(alpha: 0.2),
                                                AppTheme.primaryDriver.withValues(alpha: 0.15),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppTheme.primaryDriver.withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryDriver.withValues(alpha: 0.15),
                                                offset: Offset(0, 2),
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              child['name'].toString().substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                color: AppTheme.primaryDriver,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                child['name'] ?? 'Unknown',
                                                style: TextStyle(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              SizedBox(height: 0.4.h),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primaryDriver.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Grade ${child['grade']}',
                                                      style: TextStyle(
                                                        color: AppTheme.primaryDriver,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 2.w),
                                                  Expanded(
                                                    child: Text(
                                                      child['address'] ?? '',
                                                      style: TextStyle(
                                                        color: AppTheme.textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          if (_isExpanded && widget.assignedChildren.isEmpty) ...[
                            SizedBox(height: 1.h),
                            Text(
                              'No students assigned yet',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: icon.toString().split('.').last,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.lightDriverTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: AppTheme.lightDriverTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

