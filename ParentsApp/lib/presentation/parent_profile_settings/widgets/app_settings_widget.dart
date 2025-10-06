import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AppSettingsWidget extends StatefulWidget {
  final Map<String, dynamic> appSettings;
  final Function(Map<String, dynamic>) onSettingsUpdated;

  const AppSettingsWidget({
    Key? key,
    required this.appSettings,
    required this.onSettingsUpdated,
  }) : super(key: key);

  @override
  State<AppSettingsWidget> createState() => _AppSettingsWidgetState();
}

class _AppSettingsWidgetState extends State<AppSettingsWidget> {
  late Map<String, dynamic> _settings;
  bool _hasUnsavedChanges = false;
  final TextEditingController _feedbackController = TextEditingController();

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
    {'code': 'sw', 'name': 'Swahili', 'nativeName': 'Kiswahili'},
    {'code': 'am', 'name': 'Amharic', 'nativeName': 'አማርኛ'},
    {'code': 'ha', 'name': 'Hausa', 'nativeName': 'Hausa'},
  ];

  final List<Map<String, String>> _themes = [
    {'value': 'system', 'name': 'System Default'},
    {'value': 'light', 'name': 'Light Mode'},
    {'value': 'dark', 'name': 'Dark Mode'},
  ];

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.appSettings);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
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
        content: Text('App settings updated'),
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Language',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 3.h),
            ...(_languages
                .map((language) => ListTile(
                      leading: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.lightTheme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            language['code']!.toUpperCase(),
                            style: AppTheme.lightTheme.textTheme.labelMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        language['name']!,
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        language['nativeName']!,
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                      trailing: (_settings['language'] as String?) ==
                              language['code']
                          ? CustomIconWidget(
                              iconName: 'check_circle',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 24,
                            )
                          : null,
                      onTap: () {
                        _updateSetting('language', language['code']);
                        Navigator.of(context).pop();
                      },
                    ))
                .toList()),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Theme',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 3.h),
            ...(_themes
                .map((theme) => ListTile(
                      leading: CustomIconWidget(
                        iconName: theme['value'] == 'system'
                            ? 'brightness_auto'
                            : theme['value'] == 'light'
                                ? 'light_mode'
                                : 'dark_mode',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(
                        theme['name']!,
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                      trailing: (_settings['theme'] as String?) ==
                              theme['value']
                          ? CustomIconWidget(
                              iconName: 'check_circle',
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 24,
                            )
                          : null,
                      onTap: () {
                        _updateSetting('theme', theme['value']);
                        Navigator.of(context).pop();
                      },
                    ))
                .toList()),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Help us improve BusTracker Africa by sharing your thoughts and suggestions.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _feedbackController,
              decoration: InputDecoration(
                labelText: 'Your feedback',
                hintText: 'Tell us what you think...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _feedbackController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_feedbackController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Thank you for your feedback! We appreciate your input.'),
                    backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                    duration: Duration(seconds: 3),
                  ),
                );
                _feedbackController.clear();
              }
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    final language = _languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'name': 'English'},
    );
    return language['name']!;
  }

  String _getThemeName(String value) {
    final theme = _themes.firstWhere(
      (theme) => theme['value'] == value,
      orElse: () => {'name': 'System Default'},
    );
    return theme['name']!;
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
                iconName: 'settings',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'App Settings',
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

          // Language Selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'language',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Language',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _getLanguageName(_settings['language'] as String? ?? 'en'),
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: _showLanguageSelector,
          ),

          Divider(color: AppTheme.lightTheme.colorScheme.outline),

          // Theme Selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'palette',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Theme',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _getThemeName(_settings['theme'] as String? ?? 'system'),
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: _showThemeSelector,
          ),

          Divider(color: AppTheme.lightTheme.colorScheme.outline),

          // Auto-update Settings
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'system_update',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-update App',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Automatically download app updates',
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
                  value: _settings['autoUpdate'] as bool? ?? true,
                  onChanged: (value) => _updateSetting('autoUpdate', value),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.lightTheme.colorScheme.outline),

          // Crash Reporting
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'bug_report',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Crash Reports',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Help improve app stability',
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
                  value: _settings['crashReporting'] as bool? ?? true,
                  onChanged: (value) => _updateSetting('crashReporting', value),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.lightTheme.colorScheme.outline),

          // Feedback
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'feedback',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Send Feedback',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Share your thoughts and suggestions',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: _showFeedbackDialog,
          ),

          // App Version
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'info',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'App Version',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'v1.2.3 (Build 45)',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ),

          SizedBox(height: 3.h),

          // Save Button
          if (_hasUnsavedChanges)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save Settings'),
              ),
            ),
        ],
      ),
    );
  }
}
