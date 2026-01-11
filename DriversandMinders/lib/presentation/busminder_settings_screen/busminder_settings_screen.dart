import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/busminder_drawer_widget.dart';

class BusminderSettingsScreen extends StatefulWidget {
  const BusminderSettingsScreen({super.key});

  @override
  State<BusminderSettingsScreen> createState() =>
      _BusminderSettingsScreenState();
}

class _BusminderSettingsScreenState extends State<BusminderSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationTracking = true;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _locationTracking = prefs.getBool('location_tracking') ?? true;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.h),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBusminder,
              ),
            ),
          ),
          Divider(height: 1, color: AppTheme.borderLight),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.primaryBusminder.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryBusminder, size: 22),
      ),
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
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBusminder,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color:
              (iconColor ?? AppTheme.primaryBusminder).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.primaryBusminder,
          size: 22,
        ),
      ),
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
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'Settings',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: AppTheme.primaryBusminder,
      ),
      drawer: const BusminderDrawerWidget(currentRoute: '/busminder-settings'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Notifications Section
            _buildSettingsSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Push Notifications',
                  subtitle: 'Receive alerts for trip updates',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _saveSetting('notifications_enabled', value);
                  },
                ),
                Divider(height: 1, color: AppTheme.borderLight),
                _buildSwitchTile(
                  icon: Icons.volume_up,
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() => _soundEnabled = value);
                    _saveSetting('sound_enabled', value);
                  },
                ),
                Divider(height: 1, color: AppTheme.borderLight),
                _buildSwitchTile(
                  icon: Icons.vibration,
                  title: 'Vibration',
                  subtitle: 'Vibrate on notifications',
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                    _saveSetting('vibration_enabled', value);
                  },
                ),
              ],
            ),

            // Location Section
            _buildSettingsSection(
              title: 'Location & Tracking',
              children: [
                _buildSwitchTile(
                  icon: Icons.location_on,
                  title: 'Location Tracking',
                  subtitle: 'Share location during active trips',
                  value: _locationTracking,
                  onChanged: (value) {
                    setState(() => _locationTracking = value);
                    _saveSetting('location_tracking', value);
                  },
                ),
              ],
            ),

            // App Preferences Section
            _buildSettingsSection(
              title: 'App Preferences',
              children: [
                _buildActionTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: _language,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language selection coming soon'),
                        backgroundColor: AppTheme.primaryBusminder,
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: AppTheme.borderLight),
                _buildActionTile(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'Version 1.0.0+3',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.bus_alert,
                                color: AppTheme.primaryBusminder),
                            SizedBox(width: 2.w),
                            Text('About ApoBasi'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Version: 1.0.0+3'),
                            SizedBox(height: 1.h),
                            Text('© 2026 ApoBasi - Powered by SoG'),
                            SizedBox(height: 1.h),
                            Text(
                              'School bus tracking and attendance management for African schools.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: AppTheme.borderLight),
                _buildActionTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Privacy policy will be displayed here'),
                        backgroundColor: AppTheme.primaryBusminder,
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Footer
            Text(
              '© 2026 ApoBasi - Powered by SoG',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
