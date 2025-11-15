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
      margin: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.surface,
            AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(0.8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.25),
                      AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  width: 13.w,
                  height: 13.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.lightTheme.colorScheme.surface,
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
              ),
              SizedBox(width: 2.5.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childData['name'] ?? 'Child Name',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 13,
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            '${childData['class'] ?? 'Class Unknown'} • ${childData['school'] ?? 'School Name'}',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              fontSize: 11.sp,
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
          SizedBox(height: 1.8.h),

          // Child Details - Compact, no address
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.04),
                  AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildCompactInfoRow(Icons.badge_outlined, 'Student ID', childData['studentId'] ?? 'N/A'),
                SizedBox(height: 1.2.h),
                _buildCompactInfoRow(Icons.class_outlined, 'Grade', childData['grade'] ?? 'N/A'),
              ],
            ),
          ),

          // Track button if child is on bus
          if (_canTrackChild()) ...[
            SizedBox(height: 1.5.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 1.3.h, horizontal: 3.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.lightTheme.colorScheme.primary,
                    AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'View Live Location',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 4.5.w,
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

  Widget _buildCompactInfoRow(IconData icon, String label, String value, {bool isAddress = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: isAddress ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
