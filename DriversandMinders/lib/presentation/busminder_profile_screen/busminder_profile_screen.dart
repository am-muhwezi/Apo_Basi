import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name') ?? 'Bus Minder';
      final userPhone = prefs.getString('user_phone') ?? 'N/A';

      setState(() {
        _profileData = {
          'id': userId,
          'name': userName,
          'phone': userPhone,
          'role': 'Bus Minder',
          'email': prefs.getString('user_email') ?? 'N/A',
          'joined_date': 'January 2026',
          'trips_completed': 0,
          'attendance_recorded': 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.primaryBusminder)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.primaryBusminder,
              size: 24,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: CustomAppBar(
        title: 'My Profile',
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: AppTheme.primaryBusminder,
      ),
      drawer: const BusminderDrawerWidget(currentRoute: '/busminder-profile'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      // Profile Avatar Section
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBusminder,
                              AppTheme.primaryBusminderLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBusminder
                                  .withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primaryBusminder,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _profileData['name'] ?? 'Bus Minder',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _profileData['role'] ?? 'Bus Minder',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Statistics Section
                      Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.route,
                            label: 'Trips\nCompleted',
                            value:
                                _profileData['trips_completed']?.toString() ??
                                    '0',
                            color: AppTheme.successAction,
                          ),
                          SizedBox(width: 3.w),
                          _buildStatCard(
                            icon: Icons.how_to_reg,
                            label: 'Attendance\nRecorded',
                            value: _profileData['attendance_recorded']
                                    ?.toString() ??
                                '0',
                            color: AppTheme.warningState,
                          ),
                        ],
                      ),

                      SizedBox(height: 3.h),

                      // Contact Information
                      _buildInfoCard(
                        icon: Icons.phone,
                        label: 'Phone Number',
                        value: _profileData['phone'] ?? 'N/A',
                        iconColor: AppTheme.primaryBusminder,
                      ),

                      _buildInfoCard(
                        icon: Icons.email,
                        label: 'Email',
                        value: _profileData['email'] ?? 'N/A',
                        iconColor: AppTheme.primaryBusminder,
                      ),

                      _buildInfoCard(
                        icon: Icons.badge,
                        label: 'Employee ID',
                        value:
                            'BM-${_profileData['id']?.toString().padLeft(4, '0') ?? '0000'}',
                        iconColor: AppTheme.primaryBusminder,
                      ),

                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Joined Date',
                        value: _profileData['joined_date'] ?? 'N/A',
                        iconColor: AppTheme.primaryBusminder,
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
              ),
            ),
    );
  }
}
