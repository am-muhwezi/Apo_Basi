import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Header widget displaying current route information and trip status
class RouteHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> routeInfo;
  final int totalStudents;

  const RouteHeaderWidget({
    super.key,
    required this.routeInfo,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBusminder,
            AppTheme.primaryBusminderLight,
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBusminder.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Trip info
          Expanded(
            child: Row(
              children: [
                // Trip Type
                Text(
                  routeInfo['tripType'] as String? ?? 'Trip',
                  style: TextStyle(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right side - Compact stats
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Student count
              Icon(
                Icons.people,
                color: AppTheme.textOnPrimary,
                size: 14,
              ),
              SizedBox(width: 1.w),
              Text(
                '$totalStudents',
                style: TextStyle(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 3.w),
              // Time
              Icon(
                Icons.access_time,
                color: AppTheme.textOnPrimary,
                size: 14,
              ),
              SizedBox(width: 1.w),
              Text(
                routeInfo['startTime'] as String? ?? '--:--',
                style: TextStyle(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 3.w),
              // Status indicator
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 2.w,
                  vertical: 0.4.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successAction,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
