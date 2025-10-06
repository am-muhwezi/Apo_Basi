import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PickupDropoffMarkerWidget extends StatelessWidget {
  final String type; // 'pickup' or 'dropoff'
  final String estimatedTime;
  final bool isCompleted;
  final String studentName;

  const PickupDropoffMarkerWidget({
    Key? key,
    required this.type,
    required this.estimatedTime,
    required this.isCompleted,
    required this.studentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPickup = type == 'pickup';
    final markerColor = isCompleted
        ? AppTheme.lightTheme.colorScheme.secondary
        : isPickup
            ? AppTheme.lightTheme.colorScheme.tertiary
            : Colors.purple.shade600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Info bubble
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                studentName,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                estimatedTime,
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: markerColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 0.5.h),
        // Marker pin
        Stack(
          alignment: Alignment.center,
          children: [
            // Pin shadow
            Container(
              width: 10.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                  bottom: Radius.circular(2),
                ),
              ),
              transform: Matrix4.translationValues(1, 1, 0),
            ),
            // Main pin
            Container(
              width: 10.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: markerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                  bottom: Radius.circular(2),
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: isCompleted
                      ? 'check'
                      : isPickup
                          ? 'person_add'
                          : 'person_remove',
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            // Status indicator
            if (isCompleted)
              Positioned(
                top: -0.5.h,
                right: -0.5.w,
                child: Container(
                  width: 4.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'check',
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
