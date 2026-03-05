import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
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
  bool _darkMode = false;

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
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('About ApoBasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0+3'),
            SizedBox(height: 8),
            Text('© 2026 ApoBasi – Powered by SoG'),
            SizedBox(height: 8),
            Text(
              'School bus tracking and attendance management for African schools.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightBusminderTheme;
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme,
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Settings',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: colorScheme.primary,
      ),
      drawer: const BusminderDrawerWidget(currentRoute: '/busminder-settings'),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.3)),

            // ── Notifications ─────────────────────────────────────────
            _sectionHeader('Notifications', colorScheme),

            _GroupedCard(
              theme: theme,
              colorScheme: colorScheme,
              children: [
                _SwitchRow(
                  icon: Icons.notifications_rounded,
                  label: 'Push Notifications',
                  value: _notificationsEnabled,
                  onChanged: (v) {
                    setState(() => _notificationsEnabled = v);
                    _saveSetting('notifications_enabled', v);
                  },
                  colorScheme: colorScheme,
                ),
                _divider(colorScheme),
                _SwitchRow(
                  icon: Icons.volume_up_rounded,
                  label: 'Sound',
                  value: _soundEnabled,
                  onChanged: (v) {
                    setState(() => _soundEnabled = v);
                    _saveSetting('sound_enabled', v);
                  },
                  colorScheme: colorScheme,
                ),
                _divider(colorScheme),
                _SwitchRow(
                  icon: Icons.vibration_rounded,
                  label: 'Vibration',
                  value: _vibrationEnabled,
                  onChanged: (v) {
                    setState(() => _vibrationEnabled = v);
                    _saveSetting('vibration_enabled', v);
                  },
                  colorScheme: colorScheme,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Appearance ────────────────────────────────────────────
            _sectionHeader('Appearance', colorScheme),

            _GroupedCard(
              theme: theme,
              colorScheme: colorScheme,
              children: [
                _SwitchRow(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  value: _darkMode,
                  onChanged: (v) {
                    setState(() => _darkMode = v);
                    _saveSetting('dark_mode', v);
                  },
                  colorScheme: colorScheme,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── About ─────────────────────────────────────────────────
            _sectionHeader('About', colorScheme),

            _GroupedCard(
              theme: theme,
              colorScheme: colorScheme,
              children: [
                _NavRow(
                  icon: Icons.info_outline_rounded,
                  label: 'About ApoBasi',
                  subtitle: 'Version 1.0.0+3',
                  onTap: _showAboutDialog,
                  colorScheme: colorScheme,
                ),
                _divider(colorScheme),
                _NavRow(
                  icon: Icons.shield_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
                  colorScheme: colorScheme,
                ),
              ],
            ),

            const SizedBox(height: 40),

            Center(
              child: Text(
                '© 2026 ApoBasi – Powered by SoG',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sectionHeader(String title, ColorScheme colorScheme) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      );

  Widget _divider(ColorScheme colorScheme) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colorScheme.outline.withValues(alpha: 0.5),
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GroupedCard extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final List<Widget> children;

  const _GroupedCard({
    required this.theme,
    required this.colorScheme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme colorScheme;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
