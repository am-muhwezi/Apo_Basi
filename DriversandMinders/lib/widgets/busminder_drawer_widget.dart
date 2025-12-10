import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../services/api_service.dart';

/// Shared drawer widget for all BusMinder screens
/// This provides consistent navigation throughout the BusMinder app
class BusminderDrawerWidget extends StatelessWidget {
  final String currentRoute;

  const BusminderDrawerWidget({
    super.key,
    required this.currentRoute,
  });

  Future<Map<String, String>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? 'Busminder',
      'id': prefs.getInt('user_id')?.toString() ?? 'N/A',
    };
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.criticalAlert),
            SizedBox(width: 2.w),
            Text('Confirm Logout'),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? Your current shift data will be saved.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiService = ApiService();
              await apiService.clearToken();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/shared-login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isActive = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppTheme.primaryBusminder.withValues(alpha: 0.15),
                  AppTheme.primaryBusminderLight.withValues(alpha: 0.1),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(
                color: AppTheme.primaryBusminder.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryBusminder,
                      AppTheme.primaryBusminderLight,
                    ],
                  )
                : null,
            color: isActive ? null : AppTheme.primaryBusminder.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : AppTheme.primaryBusminder,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? AppTheme.primaryBusminder : AppTheme.textPrimary,
            letterSpacing: isActive ? 0.3 : 0,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isActive ? AppTheme.primaryBusminder : AppTheme.textSecondary,
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isActive) {
            // Use pushReplacementNamed to avoid stacking screens
            Navigator.pushReplacementNamed(context, route);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBusminder.withValues(alpha: 0.03),
              AppTheme.backgroundPrimary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Profile Header
              FutureBuilder<Map<String, String>>(
                future: _getUserInfo(),
                builder: (context, snapshot) {
                  final userInfo = snapshot.data ?? {'name': 'Busminder', 'id': 'N/A'};

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBusminder,
                          AppTheme.primaryBusminderLight,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBusminder.withValues(alpha: 0.3),
                          offset: Offset(0, 4),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                offset: Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              userInfo['name']!.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBusminder,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        // Name
                        Text(
                          userInfo['name']!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 0.5.h),
                        // ID Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'ID: ${userInfo['id']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 3.h),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      title: 'Start Shift',
                      route: '/busminder-start-shift-screen',
                      isActive: currentRoute == '/busminder-start-shift-screen',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.how_to_reg,
                      title: 'Attendance',
                      route: '/busminder-attendance-screen',
                      isActive: currentRoute == '/busminder-attendance-screen',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.route,
                      title: 'Trip Progress',
                      route: '/busminder-trip-progress-screen',
                      isActive: currentRoute == '/busminder-trip-progress-screen',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.history,
                      title: 'Trip History',
                      route: '/busminder-trip-history-screen',
                      isActive: currentRoute == '/busminder-trip-history-screen',
                    ),
                    SizedBox(height: 1.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Divider(
                        thickness: 1,
                        color: AppTheme.borderLight,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildDrawerItem(
                      context,
                      icon: Icons.person,
                      title: 'Profile',
                      route: '/busminder-profile',
                      isActive: false,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings,
                      title: 'Settings',
                      route: '/busminder-settings',
                      isActive: false,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.help,
                      title: 'Help & Support',
                      route: '/busminder-help',
                      isActive: false,
                    ),
                  ],
                ),
              ),

              // Logout button at bottom
              Container(
                padding: EdgeInsets.all(4.w),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.criticalAlert,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 20),
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
            ],
          ),
        ),
      ),
    );
  }
}
