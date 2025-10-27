import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChildInformationWidget extends StatelessWidget {
  final Map<String, dynamic> childData;
  final VoidCallback? onTap;

  const ChildInformationWidget({
    Key? key,
    required this.childData,
    this.onTap,
  }) : super(key: key);

  bool _canTrackChild() {
    final status = (childData['status'] ?? 'no record today').toString().toLowerCase();
    return status != 'at_home' &&
           status != 'at_school' &&
           status != 'no record today';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final canTrack = _canTrackChild();

    return GestureDetector(
      onTap: canTrack ? (onTap ?? () => _navigateToLiveMap(context)) : null,
      child: Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    _getInitials(childData['name'] ?? 'Child Name'),
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childData['name'] ?? 'Child Name',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${childData['class'] ?? 'Class Unknown'} • ${childData['school'] ?? 'School Name'}',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Child Details
          _buildInfoRow('Student ID', childData['studentId'] ?? 'N/A'),
          SizedBox(height: 2.h),
          _buildInfoRow('Grade', childData['grade'] ?? 'N/A'),
          SizedBox(height: 2.h),
          _buildInfoRow('School', childData['school'] ?? 'School Name'),
          SizedBox(height: 2.h),
          _buildInfoRow(
            'Home Address',
            childData['homeAddress'] ?? 'Address not set',
            isAddress: true,
          ),

          // Track button if child is on bus
          if (_canTrackChild()) ...[
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Tap to view details',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 4.w,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _navigateToLiveMap(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/child-detail',
      arguments: childData,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAddress = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 25.w,
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          ':',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            maxLines: isAddress ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
