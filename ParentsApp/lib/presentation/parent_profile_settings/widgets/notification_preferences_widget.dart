import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationPreferencesWidget extends StatefulWidget {
  final Map<String, dynamic> notificationSettings;
  final Function(Map<String, dynamic>) onSettingsUpdated;

  const NotificationPreferencesWidget({
    Key? key,
    required this.notificationSettings,
    required this.onSettingsUpdated,
  }) : super(key: key);

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  late Map<String, dynamic> _settings;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.notificationSettings);
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _settings[key] = value;
      _hasUnsavedChanges = true;
    });
  }

  void _saveSettings() {
    widget.onSettingsUpdated(_settings);
    setState(() {
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification preferences updated'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required String settingKey,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: icon.toString().split('.').last,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings[settingKey] as bool? ?? false,
            onChanged: (value) => _updateSetting(settingKey, value),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSlider({
    required String title,
    required String settingKey,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) labelFormatter,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 1.h),
          Slider(
            value: (_settings[settingKey] as num?)?.toDouble() ?? min,
            min: min,
            max: max,
            divisions: divisions,
            label: labelFormatter(
                (_settings[settingKey] as num?)?.toDouble() ?? min),
            onChanged: (value) => _updateSetting(settingKey, value.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelFormatter(min),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                labelFormatter(max),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'notifications',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Notification Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Spacer(),
              if (_hasUnsavedChanges)
                Container(
                  width: 2.w,
                  height: 2.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.h),

          // Bus Proximity Alerts
          _buildToggleItem(
            title: 'Bus Proximity Alerts',
            subtitle: 'Get notified when bus is approaching pickup/dropoff',
            settingKey: 'busProximityAlerts',
            icon: Icons.location_on,
          ),

          // Pickup Confirmations
          _buildToggleItem(
            title: 'Pickup Confirmations',
            subtitle: 'Receive confirmation when child is picked up',
            settingKey: 'pickupConfirmations',
            icon: Icons.check_circle,
          ),

          // Route Changes
          _buildToggleItem(
            title: 'Route Changes',
            subtitle: 'Be informed about any changes to bus routes',
            settingKey: 'routeChanges',
            icon: Icons.alt_route,
          ),

          // Emergency Notifications
          _buildToggleItem(
            title: 'Emergency Notifications',
            subtitle: 'Critical alerts about safety and emergencies',
            settingKey: 'emergencyNotifications',
            icon: Icons.warning,
          ),

          SizedBox(height: 2.h),
          Divider(color: Theme.of(context).colorScheme.outline),
          SizedBox(height: 2.h),

          Text(
            'Timing Controls',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 2.h),

          // Proximity Alert Distance
          _buildTimingSlider(
            title: 'Proximity Alert Distance',
            settingKey: 'proximityDistance',
            min: 1,
            max: 10,
            divisions: 9,
            labelFormatter: (value) => '${value.round()} km',
          ),

          // Advance Notice Time
          _buildTimingSlider(
            title: 'Advance Notice Time',
            settingKey: 'advanceNoticeTime',
            min: 5,
            max: 30,
            divisions: 5,
            labelFormatter: (value) => '${value.round()} min',
          ),

          SizedBox(height: 2.h),

          // Quiet Hours Section
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'bedtime',
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Quiet Hours',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Spacer(),
                    Switch(
                      value: _settings['quietHoursEnabled'] as bool? ?? false,
                      onChanged: (value) =>
                          _updateSetting('quietHoursEnabled', value),
                    ),
                  ],
                ),
                if (_settings['quietHoursEnabled'] as bool? ?? false) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              _settings['quietHoursStart'] as String? ??
                                  '22:00',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              _settings['quietHoursEnd'] as String? ?? '07:00',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Save Button
          if (_hasUnsavedChanges)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save Preferences'),
              ),
            ),
        ],
      ),
    );
  }
}
