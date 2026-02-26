import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RouteAssignmentCardWidget extends StatelessWidget {
  final String routeName;
  final int studentCount;
  final List<Map<String, dynamic>> assignedChildren;
  final VoidCallback? onTap;
  final String? busNumber;
  final String? routeNameOnly;

  const RouteAssignmentCardWidget({
    super.key,
    required this.routeName,
    required this.studentCount,
    this.assignedChildren = const [],
    this.onTap,
    this.busNumber,
    this.routeNameOnly,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
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
                if (busNumber != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: _buildInfoRow(
                      'Bus Number',
                      busNumber!,
                      Icons.directions_bus,
                    ),
                  ),
                if (routeNameOnly != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: _buildInfoRow(
                      'Route',
                      routeNameOnly!,
                      Icons.route,
                    ),
                  ),
                _buildInfoRow(
                  'Route Assignment',
                  routeName,
                  Icons.route,
                ),
                SizedBox(height: 2.h),
                _buildInfoRow(
                  'Number of Students',
                  '$studentCount students',
                  Icons.people,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: cardContent,
            )
          : cardContent,
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
