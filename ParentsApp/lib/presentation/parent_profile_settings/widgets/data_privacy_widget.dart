import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DataPrivacyWidget extends StatefulWidget {
  final Map<String, dynamic> privacySettings;
  final Function(Map<String, dynamic>) onSettingsUpdated;

  const DataPrivacyWidget({
    Key? key,
    required this.privacySettings,
    required this.onSettingsUpdated,
  }) : super(key: key);

  @override
  State<DataPrivacyWidget> createState() => _DataPrivacyWidgetState();
}

class _DataPrivacyWidgetState extends State<DataPrivacyWidget> {
  late Map<String, dynamic> _settings;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.privacySettings);
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
        content: Text('Privacy settings updated'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BusTracker Africa Privacy Policy',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Data Collection:',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                '• Location data for bus tracking\n• Student information for safety\n• Contact details for emergencies\n• Usage analytics for app improvement',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Data Usage:',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                '• Real-time tracking and notifications\n• Safety and security purposes\n• Communication with parents\n• Service improvement',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Data Protection:',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                '• Encrypted data transmission\n• Secure server storage\n• Limited access controls\n• Regular security audits',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDataUsage(double mb) {
    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
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
                iconName: 'privacy_tip',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Data & Privacy',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              if (_hasUnsavedChanges)
                Container(
                  width: 2.w,
                  height: 2.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.h),

          // Data Usage Statistics
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'data_usage',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Data Usage This Month',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Used',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                        Text(
                          _formatDataUsage((_settings['totalDataUsed'] as num?)
                                  ?.toDouble() ??
                              45.7),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maps & Tracking',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                        Text(
                          _formatDataUsage(
                              (_settings['mapsDataUsed'] as num?)?.toDouble() ??
                                  32.1),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                        Text(
                          _formatDataUsage(
                              (_settings['notificationDataUsed'] as num?)
                                      ?.toDouble() ??
                                  13.6),
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Offline Mode Preferences
          Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'offline_bolt',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Cache data for low connectivity areas',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _settings['offlineModeEnabled'] as bool? ?? true,
                  onChanged: (value) =>
                      _updateSetting('offlineModeEnabled', value),
                ),
              ],
            ),
          ),

          // Data Saver Mode
          Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'data_saver_on',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Saver Mode',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Reduce data usage with compressed content',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _settings['dataSaverEnabled'] as bool? ?? false,
                  onChanged: (value) =>
                      _updateSetting('dataSaverEnabled', value),
                ),
              ],
            ),
          ),

          // Location Data Sharing
          Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'location_on',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Location Data',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Help improve route optimization',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _settings['shareLocationData'] as bool? ?? true,
                  onChanged: (value) =>
                      _updateSetting('shareLocationData', value),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),
          Divider(color: AppTheme.lightTheme.colorScheme.outline),
          SizedBox(height: 2.h),

          // Privacy Policy Access
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'policy',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Privacy Policy',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'View our complete privacy policy',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: _showPrivacyPolicy,
          ),

          // Data Export
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'download',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Export My Data',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Download a copy of your data',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Data export request submitted. You will receive an email within 24 hours.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),

          SizedBox(height: 3.h),

          // Save Button
          if (_hasUnsavedChanges)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save Privacy Settings'),
              ),
            ),
        ],
      ),
    );
  }
}
