import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';
  String _distanceUnit = 'Kilometers';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _locationTrackingEnabled = prefs.getBool('location_tracking_enabled') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
        _language = prefs.getString('language') ?? 'English';
        _distanceUnit = prefs.getString('distance_unit') ?? 'Kilometers';
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setting saved'),
          backgroundColor: AppTheme.successAction,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save setting'),
          backgroundColor: AppTheme.criticalAlert,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout? Any unsaved data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Clear all user data
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Navigate to login
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/shared-login-screen',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalAlert,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: CustomAppBar(
          title: 'Settings',
          subtitle: 'Manage app preferences',
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 2.h),

              // Notifications Section
              _buildSection(
                title: 'Notifications',
                icon: Icons.notifications,
                children: [
                  _buildSwitchTile(
                    title: 'Enable Notifications',
                    subtitle: 'Receive push notifications for updates',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSetting('notifications_enabled', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Sound',
                    subtitle: 'Play sound for notifications',
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                      _saveSetting('sound_enabled', value);
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Vibration',
                    subtitle: 'Vibrate on notifications',
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _vibrationEnabled = value;
                      });
                      _saveSetting('vibration_enabled', value);
                    },
                  ),
                ],
              ),

              // Location & Tracking Section
              _buildSection(
                title: 'Location & Tracking',
                icon: Icons.location_on,
                children: [
                  _buildSwitchTile(
                    title: 'Location Tracking',
                    subtitle: 'Allow app to track your location',
                    value: _locationTrackingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationTrackingEnabled = value;
                      });
                      _saveSetting('location_tracking_enabled', value);
                    },
                  ),
                ],
              ),

              // Appearance Section
              _buildSection(
                title: 'Appearance',
                icon: Icons.palette,
                children: [
                  _buildSwitchTile(
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme',
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                      _saveSetting('dark_mode_enabled', value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dark mode will be available in a future update'),
                          backgroundColor: AppTheme.primaryDriver,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Language & Region Section
              _buildSection(
                title: 'Language & Region',
                icon: Icons.language,
                children: [
                  _buildDropdownTile(
                    title: 'Language',
                    subtitle: 'Select your preferred language',
                    value: _language,
                    items: ['English', 'Spanish', 'French', 'German'],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _language = value;
                        });
                        _saveSetting('language', value);
                      }
                    },
                  ),
                  _buildDropdownTile(
                    title: 'Distance Unit',
                    subtitle: 'Choose distance measurement unit',
                    value: _distanceUnit,
                    items: ['Kilometers', 'Miles'],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _distanceUnit = value;
                        });
                        _saveSetting('distance_unit', value);
                      }
                    },
                  ),
                ],
              ),

              // About Section
              _buildSection(
                title: 'About',
                icon: Icons.info,
                children: [
                  _buildInfoTile(
                    title: 'Version',
                    value: '1.0.0',
                    icon: Icons.app_settings_alt,
                  ),
                  _buildInfoTile(
                    title: 'Build Number',
                    value: '100',
                    icon: Icons.tag,
                  ),
                  _buildActionTile(
                    title: 'Terms of Service',
                    icon: Icons.description,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Terms of Service coming soon')),
                      );
                    },
                  ),
                  _buildActionTile(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Privacy Policy coming soon')),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: ElevatedButton(
                  onPressed: _showLogoutConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.criticalAlert,
                    foregroundColor: AppTheme.textOnPrimary,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 2.w),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryDriver.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryDriver,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDriver,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Column(
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          HapticFeedback.lightImpact();
          onChanged(newValue);
        },
        activeColor: AppTheme.primaryDriver,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: (newValue) {
          HapticFeedback.lightImpact();
          onChanged(newValue);
        },
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        underline: Container(),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      leading: Icon(
        icon,
        color: AppTheme.primaryDriver,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      leading: Icon(
        icon,
        color: AppTheme.primaryDriver,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
