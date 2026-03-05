import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/busminder_drawer_widget.dart';

class BusminderProfileScreen extends StatefulWidget {
  const BusminderProfileScreen({super.key});

  @override
  State<BusminderProfileScreen> createState() => _BusminderProfileScreenState();
}

class _BusminderProfileScreenState extends State<BusminderProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _profileData = {
          'id': prefs.getInt('user_id'),
          'name': prefs.getString('user_name') ?? 'Bus Minder',
          'phone': prefs.getString('user_phone') ?? 'N/A',
          'role': 'Bus Minder',
          'email': prefs.getString('user_email') ?? 'N/A',
          'joined_date': 'January 2026',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String get _initials {
    final name = (_profileData['name'] ?? '').toString().trim();
    if (name.isEmpty) return 'B';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String get _employeeId {
    final id = _profileData['id'];
    return 'BM-${id?.toString().padLeft(4, '0') ?? '0000'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'My Profile',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: colorScheme.primary,
      ),
      drawer: const BusminderDrawerWidget(currentRoute: '/busminder-profile'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),

                    // ── Profile header ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.primary.withValues(alpha: 0.15)
                                  : colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _initials,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profileData['name'] ?? 'Bus Minder',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _profileData['role'] ?? 'Bus Minder',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profileData['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Contact Information ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone Number',
                            value: _profileData['phone'] ?? 'N/A',
                            colorScheme: colorScheme,
                          ),
                          _divider(colorScheme),
                          _InfoRow(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: _profileData['email'] ?? 'N/A',
                            colorScheme: colorScheme,
                          ),
                          _divider(colorScheme),
                          _InfoRow(
                            icon: Icons.badge_rounded,
                            label: 'Employee ID',
                            value: _employeeId,
                            colorScheme: colorScheme,
                          ),
                          _divider(colorScheme),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Joined Date',
                            value: _profileData['joined_date'] ?? 'N/A',
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

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

  Widget _divider(ColorScheme colorScheme) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colorScheme.outline.withValues(alpha: 0.5),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
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
