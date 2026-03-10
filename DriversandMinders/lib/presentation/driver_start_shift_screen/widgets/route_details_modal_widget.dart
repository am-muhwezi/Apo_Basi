import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RouteDetailsModalWidget extends StatelessWidget {
  final Map<String, dynamic> routeData;
  final VoidCallback onClose;

  const RouteDetailsModalWidget({
    super.key,
    required this.routeData,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightDriverTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Route Details',
                  style: AppTheme.lightDriverTheme.textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Map Preview
                  Container(
                    height: 25.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomImageWidget(
                            imageUrl: routeData['mapPreview'] as String,
                            width: double.infinity,
                            height: 25.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2.w,
                          right: 2.w,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme
                                  .lightDriverTheme.colorScheme.surface
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomIconWidget(
                              iconName: 'fullscreen',
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Route Information
                  _buildSectionTitle('Route Information'),
                  SizedBox(height: 2.h),

                  _buildInfoCard([
                    _buildInfoRow('Route Name',
                        routeData['routeName'] as String, 'route'),
                    _buildInfoRow('Total Distance',
                        routeData['totalDistance'] as String, 'straighten'),
                    _buildInfoRow('Estimated Time',
                        routeData['estimatedTime'] as String, 'access_time'),
                    _buildInfoRow('Total Stops',
                        '${routeData['totalStops']} stops', 'location_on'),
                  ]),

                  SizedBox(height: 3.h),

                  // Student Information
                  _buildSectionTitle('Student Information'),
                  SizedBox(height: 2.h),

                  _buildInfoCard([
                    _buildInfoRow('Total Students',
                        '${routeData['totalStudents']} students', 'people'),
                    _buildInfoRow('Morning Pickup',
                        '${routeData['morningPickup']} students', 'wb_sunny'),
                    _buildInfoRow(
                        'Afternoon Drop',
                        '${routeData['afternoonDrop']} students',
                        'wb_twilight'),
                  ]),

                  SizedBox(height: 3.h),

                  // Key Stops
                  _buildSectionTitle('Key Stops'),
                  SizedBox(height: 2.h),

                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: (routeData['keyStops'] as List).map((stop) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 2.h),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (stop as Map<String, dynamic>)['name']
                                          as String,
                                      style: AppTheme
                                          .lightDriverTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${stop['studentCount']} students • ${stop['estimatedTime']}',
                                      style: AppTheme
                                          .lightDriverTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
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

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.lightDriverTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String iconName) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      AppTheme.lightDriverTheme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style:
                      AppTheme.lightDriverTheme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

