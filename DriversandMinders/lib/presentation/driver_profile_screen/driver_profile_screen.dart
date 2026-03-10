import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/theme_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/driver_drawer_widget.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final ThemeService _themeService = ThemeService();

  bool _isLoading = true;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Location
  bool _locationTrackingEnabled = true;

  // Region
  String _language = 'English';
  String _distanceUnit = 'Kilometers';

  Map<String, dynamic> _driverInfo = {};
  Map<String, dynamic>? _busInfo;
  Map<String, dynamic>? _routeInfo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _locationTrackingEnabled = prefs.getBool('location_tracking_enabled') ?? true;
    _language = prefs.getString('language') ?? 'English';
    _distanceUnit = prefs.getString('distance_unit') ?? 'Kilometers';

    _driverInfo = {
      'name': prefs.getString('driver_name') ??
          prefs.getString('user_name') ??
          'Driver',
      'id': (prefs.getInt('driver_id') ?? prefs.getInt('user_id'))
              ?.toString() ??
          'N/A',
      'email': prefs.getString('driver_email') ??
          prefs.getString('user_email') ??
          'Not available',
      'phone': prefs.getString('driver_phone') ??
          prefs.getString('user_phone') ??
          'Not available',
      'licenseNumber': prefs.getString('license_number') ?? 'Not available',
      'licenseExpiry': prefs.getString('license_expiry') ?? 'Not available',
      'joinDate': prefs.getString('join_date') ?? 'Not available',
    };

    final cachedBusData = prefs.getString('cached_bus_data');
    _busInfo = null;
    if (cachedBusData != null) {
      try {
        final decoded = jsonDecode(cachedBusData);
        if (decoded is Map<String, dynamic>) {
          _busInfo = {
            'busNumber': decoded['bus_number']?.toString() ??
                prefs.getString('bus_number') ??
                'Not assigned',
            'busPlate': decoded['number_plate']?.toString() ??
                prefs.getString('bus_plate') ??
                'N/A',
            'capacity':
                (decoded['capacity'] ?? decoded['bus_capacity'])?.toString() ??
                    prefs.getInt('bus_capacity')?.toString() ??
                    'N/A',
            'childrenCount': decoded['children_count'] ??
                (decoded['children'] is List
                    ? (decoded['children'] as List).length
                    : null),
          };
        }
      } catch (_) {}
    }

    final cachedRouteData = prefs.getString('cached_route_data');
    _routeInfo = null;
    if (cachedRouteData != null) {
      try {
        final decoded = jsonDecode(cachedRouteData);
        if (decoded is Map<String, dynamic>) {
          final children = decoded['children'];
          final totalChildren = decoded['total_children'] ??
              decoded['children_count'] ??
              (children is List ? children.length : null);
          final totalStops = decoded['total_stops'] ??
              decoded['total_assignments'] ??
              (children is List ? children.length : null);

          _routeInfo = {
            'routeName': decoded['route_name']?.toString() ??
                decoded['name']?.toString() ??
                prefs.getString('route_name') ??
                'Not assigned',
            'totalStops': totalStops?.toString() ??
                prefs.getInt('total_stops')?.toString() ??
                'N/A',
            'totalStudents': totalChildren?.toString() ??
                (_busInfo?['childrenCount']?.toString()) ??
                prefs.getInt('total_students')?.toString() ??
                'N/A',
          };
        }
      } catch (_) {
        _routeInfo = {
          'routeName': prefs.getString('route_name') ?? 'Not assigned',
          'totalStops': prefs.getInt('total_stops')?.toString() ?? 'N/A',
          'totalStudents': prefs.getInt('total_students')?.toString() ?? 'N/A',
        };
      }
    } else {
      _routeInfo = {
        'routeName': prefs.getString('route_name') ?? 'Not assigned',
        'totalStops': prefs.getInt('total_stops')?.toString() ?? 'N/A',
        'totalStudents': prefs.getInt('total_students')?.toString() ?? 'N/A',
      };
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _setDarkMode(bool value) async {
    await _themeService.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    setState(() {});
  }

  void _showLogoutDialog() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 32),
            ),
            SizedBox(height: 2.h),
            // Title
            Text(
              'Logout?',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 1.h),
            // Subtitle
            Text(
              'You will need to login again to access your account',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: 3.h),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                          color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    child: Text('Cancel',
                        style: tt.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/shared-login-screen', (_) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Logout',
                        style: tt.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                      _savePref('language', lang);
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
                      _savePref('distance_unit', unit);
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
    final isDark = _themeService.themeMode == ThemeMode.dark;
    final driverName = _driverInfo['name'] as String? ?? 'Driver';

    return Scaffold(
      drawer: DriverDrawerWidget(
        currentRoute: '/driver-profile-screen',
        driverData: {'driverName': driverName},
      ),
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: cs.onSurface),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        title: Text(
          'Profile & Settings',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),

                  // ── Profile Header ─────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      children: [
                        _Avatar(
                          label: driverName.substring(0, 1).toUpperCase(),
                          size: 72,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: tt.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _driverInfo['email'] as String? ??
                                    'Not available',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              Text(
                                _driverInfo['phone'] as String? ??
                                    'Not available',
                                style: tt.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Edit profile coming soon')),
                          ),
                          icon: Icon(Icons.edit_outlined,
                              color: cs.primary, size: 22),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  SizedBox(height: 2.5.h),

                  // ── Bus Assignment ─────────────────────────────────────
                  _sectionHeader('Bus Assignment'),
                  SizedBox(height: 1.5.h),

                  if (_busInfo != null)
                    _AssignmentItem(
                      icon: Icons.directions_bus_rounded,
                      label: _busInfo!['busNumber'] as String? ??
                          'Not assigned',
                      subtitle:
                          'Plate: ${_busInfo!['busPlate'] as String? ?? 'N/A'}  ·  Capacity: ${_busInfo!['capacity'] as String? ?? 'N/A'}',
                    ),

                  if (_routeInfo != null)
                    _AssignmentItem(
                      icon: Icons.route_rounded,
                      label: _routeInfo!['routeName'] as String? ??
                          'Not assigned',
                      subtitle:
                          'Stops: ${_routeInfo!['totalStops'] as String? ?? 'N/A'}  ·  Students: ${_routeInfo!['totalStudents'] as String? ?? 'N/A'}',
                    ),

                  if (_busInfo == null && _routeInfo == null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text('No assignment data',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ),

                  SizedBox(height: 2.5.h),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  SizedBox(height: 2.5.h),

                  // ── Notifications ──────────────────────────────────────
                  _sectionHeader('Notifications'),
                  SizedBox(height: 1.5.h),
                  _SettingsCard(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    children: [
                      _ToggleRow(
                        label: 'Push Notifications',
                        subtitle: 'Receive updates and alerts',
                        value: _notificationsEnabled,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _notificationsEnabled = v);
                          _savePref('notifications_enabled', v);
                        },
                      ),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.4)),
                      _ToggleRow(
                        label: 'Sound',
                        subtitle: 'Play audio for notifications',
                        value: _soundEnabled,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _soundEnabled = v);
                          _savePref('sound_enabled', v);
                        },
                      ),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.4)),
                      _ToggleRow(
                        label: 'Vibration',
                        subtitle: 'Vibrate on new notifications',
                        value: _vibrationEnabled,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _vibrationEnabled = v);
                          _savePref('vibration_enabled', v);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 2.5.h),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  SizedBox(height: 2.5.h),

                  // ── Location & Tracking ────────────────────────────────
                  _sectionHeader('Location & Tracking'),
                  SizedBox(height: 1.5.h),
                  _SettingsCard(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    children: [
                      _ToggleRow(
                        label: 'Background Location',
                        subtitle: 'Track GPS during active trips',
                        value: _locationTrackingEnabled,
                        onChanged: (v) {
                          HapticFeedback.lightImpact();
                          setState(() => _locationTrackingEnabled = v);
                          _savePref('location_tracking_enabled', v);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 2.5.h),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  SizedBox(height: 2.5.h),

                  // ── Appearance ─────────────────────────────────────────
                  _sectionHeader('Appearance'),
                  SizedBox(height: 1.5.h),
                  _SettingsCard(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    children: [
                      _ToggleRow(
                        label: 'Dark Mode',
                        subtitle: 'Switch to dark theme',
                        value: isDark,
                        onChanged: _setDarkMode,
                      ),
                    ],
                  ),

                  SizedBox(height: 2.5.h),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  SizedBox(height: 2.5.h),

                  // ── Language & Region ──────────────────────────────────
                  _sectionHeader('Language & Region'),
                  SizedBox(height: 1.5.h),
                  _SettingsCard(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    children: [
                      _NavRow(
                        label: 'Language',
                        trailing: _language,
                        onTap: _showLanguageSheet,
                      ),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.4)),
                      _NavRow(
                        label: 'Distance Unit',
                        trailing: _distanceUnit,
                        onTap: _showDistanceSheet,
                      ),
                    ],
                  ),

                  SizedBox(height: 2.5.h),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  SizedBox(height: 2.5.h),

                  // ── About ──────────────────────────────────────────────
                  _sectionHeader('About'),
                  SizedBox(height: 1.5.h),
                  _SettingsCard(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    children: [
                      _InfoRow(label: 'Version', value: '1.0.0'),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.4)),
                      _NavRow(
                        label: 'Terms of Service',
                        trailing: '',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.apobasi.com/terms'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.4)),
                      _NavRow(
                        label: 'Privacy Policy',
                        trailing: '',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.apobasi.com/privacy'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.5.h),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                  SizedBox(height: 2.5.h),

                  // ── Account ────────────────────────────────────────────
                  _sectionHeader('Account'),
                  SizedBox(height: 1.5.h),
                  _SettingsCard(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    children: [
                      _InfoRow(
                        label: 'Driver ID',
                        value: _driverInfo['id'] as String? ?? 'N/A',
                      ),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.4)),
                      _InfoRow(
                        label: 'License',
                        value: _driverInfo['licenseNumber'] as String? ?? 'N/A',
                      ),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.4)),
                      _InfoRow(
                        label: 'Join Date',
                        value: _driverInfo['joinDate'] as String? ?? 'N/A',
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // ── Logout ─────────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _showLogoutDialog,
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: cs.error,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/driver-start-shift-screen');
              break;
            case 1:
              Navigator.pushNamed(context, '/driver-active-trip-screen');
              break;
            case 2:
              break;
          }
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
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

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String label;
  final double size;

  const _Avatar({required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _AssignmentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _AssignmentItem({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
            ),
            child: Icon(icon, color: cs.primary, size: 24),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const _SettingsCard({
    required this.children,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
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
