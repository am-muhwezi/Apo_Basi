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
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 3.h),
            ...(_languages
                .map((language) => ListTile(
                      leading: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            language['code']!.toUpperCase(),
                            style: AppTheme.lightTheme.textTheme.labelMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        language['name']!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        language['nativeName']!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing:
                          (_settings['language'] as String?) == language['code']
                              ? CustomIconWidget(
                                  iconName: 'check_circle',
                                  color: Theme.of(context).colorScheme.primary,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Select Theme',
              style: Theme.of(context).textTheme.titleLarge,
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
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(
                        theme['name']!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing:
                          (_settings['theme'] as String?) == theme['value']
                              ? CustomIconWidget(
                                  iconName: 'check_circle',
                                  color: Theme.of(context).colorScheme.primary,
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
                    backgroundColor: Theme.of(context).colorScheme.secondary,
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
                iconName: 'settings',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'App Settings',
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

          // Language Selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'language',
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Language',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Text(
              _getLanguageName(_settings['language'] as String? ?? 'en'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: _showLanguageSelector,
          ),

          Divider(color: Theme.of(context).colorScheme.outline),

          // Theme Selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'palette',
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Theme',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Text(
              _getThemeName(_settings['theme'] as String? ?? 'system'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: _showThemeSelector,
          ),

          Divider(color: Theme.of(context).colorScheme.outline),

          // Auto-update Settings
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'system_update',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-update App',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Automatically download app updates',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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

          Divider(color: Theme.of(context).colorScheme.outline),

          // Crash Reporting
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'bug_report',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Crash Reports',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Help improve app stability',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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

          Divider(color: Theme.of(context).colorScheme.outline),

          // Feedback
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'feedback',
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Send Feedback',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Text(
              'Share your thoughts and suggestions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
            onTap: _showFeedbackDialog,
          ),

          // App Version
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CustomIconWidget(
              iconName: 'info',
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'App Version',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Text(
              'v1.2.3 (Build 45)',
              style: Theme.of(context).textTheme.bodySmall,
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
