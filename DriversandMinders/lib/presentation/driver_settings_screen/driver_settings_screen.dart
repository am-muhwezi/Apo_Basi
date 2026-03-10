import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_bottom_bar.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  // Notifications
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Tracking
  bool _locationTrackingEnabled = true;

  // Region
  String _language = 'English';
  String _distanceUnit = 'Kilometers';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _locationTrackingEnabled =
          prefs.getBool('location_tracking_enabled') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _distanceUnit = prefs.getString('distance_unit') ?? 'Kilometers';
    });
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _showLanguageSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    const languages = ['English', 'French', 'Swahili', 'Hausa'];
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text('Select Language', style: tt.titleMedium),
              SizedBox(height: 1.h),
              ...languages.map((lang) => ListTile(
                    title: Text(lang, style: tt.bodyLarge),
                    trailing: _language == lang
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                    onTap: () {
                      setState(() => _language = lang);
                      _save('language', lang);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showDistanceSheet() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    const units = ['Kilometers', 'Miles'];
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text('Distance Unit', style: tt.titleMedium),
              SizedBox(height: 1.h),
              ...units.map((unit) => ListTile(
                    title: Text(unit, style: tt.bodyLarge),
                    trailing: _distanceUnit == unit
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                    onTap: () {
                      setState(() => _distanceUnit = unit);
                      _save('distance_unit', unit);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
            SizedBox(height: 2.5.h),

            // ── Notifications ──────────────────────────────────────
            _sectionHeader('Notifications', context),
            SizedBox(height: 1.5.h),
            _SettingsCard(children: [
              _ToggleRow(
                label: 'Push Notifications',
                subtitle: 'Receive updates and alerts',
                value: _notificationsEnabled,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _notificationsEnabled = v);
                  _save('notifications_enabled', v);
                },
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _ToggleRow(
                label: 'Sound',
                subtitle: 'Play audio for notifications',
                value: _soundEnabled,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _soundEnabled = v);
                  _save('sound_enabled', v);
                },
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _ToggleRow(
                label: 'Vibration',
                subtitle: 'Vibrate on new notifications',
                value: _vibrationEnabled,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _vibrationEnabled = v);
                  _save('vibration_enabled', v);
                },
              ),
            ]),

            SizedBox(height: 2.5.h),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
            SizedBox(height: 2.5.h),

            // ── Location ───────────────────────────────────────────
            _sectionHeader('Location & Tracking', context),
            SizedBox(height: 1.5.h),
            _SettingsCard(children: [
              _ToggleRow(
                label: 'Background Location',
                subtitle: 'Track GPS during active trips',
                value: _locationTrackingEnabled,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _locationTrackingEnabled = v);
                  _save('location_tracking_enabled', v);
                },
              ),
            ]),

            SizedBox(height: 2.5.h),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
            SizedBox(height: 2.5.h),

            // ── Language & Region ──────────────────────────────────
            _sectionHeader('Language & Region', context),
            SizedBox(height: 1.5.h),
            _SettingsCard(children: [
              _NavRow(
                label: 'Language',
                trailing: _language,
                onTap: _showLanguageSheet,
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _NavRow(
                label: 'Distance Unit',
                trailing: _distanceUnit,
                onTap: _showDistanceSheet,
              ),
            ]),

            SizedBox(height: 2.5.h),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
            SizedBox(height: 2.5.h),

            // ── About ──────────────────────────────────────────────
            _sectionHeader('About', context),
            SizedBox(height: 1.5.h),
            _SettingsCard(children: [
              _InfoRow(label: 'Version', value: '1.0.0'),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _InfoRow(label: 'Build', value: '100'),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _NavRow(
                label: 'Terms of Service',
                trailing: '',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terms of Service coming soon')),
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.4)),
              _NavRow(
                label: 'Privacy Policy',
                trailing: '',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy Policy coming soon')),
                ),
              ),
            ]),

            SizedBox(height: 4.h),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: -1, // Settings isn't a bottom-tab destination
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/driver-start-shift-screen');
              break;
            case 1:
              Navigator.pushNamed(context, '/driver-active-trip-screen');
              break;
            case 2:
              Navigator.pushNamed(context, '/driver-profile-screen');
              break;
          }
        },
      ),
    );
  }

  Widget _sectionHeader(String title, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Shared card container ─────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: cs.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

// ── Row types ─────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final String trailing;
  final VoidCallback onTap;

  const _NavRow({
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title:
          Text(label, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(trailing,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title:
          Text(label, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      trailing:
          Text(value, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}
