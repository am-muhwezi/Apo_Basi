import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _driverInfo = {};
  Map<String, dynamic>? _busInfo;
  Map<String, dynamic>? _routeInfo;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get driver information from SharedPreferences
      _driverInfo = {
        'name': prefs.getString('driver_name') ??
            prefs.getString('user_name') ??
            'Driver',
        'id': (prefs.getInt('driver_id') ?? prefs.getInt('user_id'))
                ?.toString() ??
            'N/A',
        'email': prefs.getString('driver_email') ??
            prefs.getString('user_email') ??
            'Not Available',
        'phone': prefs.getString('driver_phone') ??
            prefs.getString('user_phone') ??
            'Not Available',
        'licenseNumber': prefs.getString('license_number') ?? 'Not Available',
        'licenseExpiry': prefs.getString('license_expiry') ?? 'Not Available',
        'joinDate': prefs.getString('join_date') ?? 'Not Available',
        'address': prefs.getString('user_address') ?? 'Not Available',
        'dob': prefs.getString('user_dob') ?? 'Not Available',
        'nationalId': prefs.getString('user_national_id') ?? 'Not Available',
        'gender': prefs.getString('user_gender') ?? 'Not Available',
      };

      // Get cached bus and route information used on Home/Start Shift
      final cachedBusData = prefs.getString('cached_bus_data');
      final cachedRouteData = prefs.getString('cached_route_data');

      // Prefer parsing cached JSON (same data the home screen uses)
      _busInfo = null;
      if (cachedBusData != null) {
        try {
          final decoded = jsonDecode(cachedBusData);
          if (decoded is Map<String, dynamic>) {
            _busInfo = {
              'busNumber': decoded['bus_number']?.toString() ??
                  prefs.getString('bus_number') ??
                  'Not Assigned',
              'busPlate': decoded['number_plate']?.toString() ??
                  prefs.getString('bus_plate') ??
                  'N/A',
              'capacity': (decoded['capacity'] ?? decoded['bus_capacity'])
                      ?.toString() ??
                  prefs.getInt('bus_capacity')?.toString() ??
                  'N/A',
              // Children assigned directly to the bus (from unified login)
              'childrenCount': decoded['children_count'] ??
                  (decoded['children'] is List
                      ? (decoded['children'] as List).length
                      : null),
            };
          }
        } catch (e) {
          _busInfo = null;
        }
      }

      // Get route information from cached data
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
                  'Not Assigned',
              'totalStops': totalStops?.toString() ??
                  prefs.getInt('total_stops')?.toString() ??
                  'N/A',
              'totalStudents': totalChildren?.toString() ??
                  (_busInfo?['childrenCount']?.toString()) ??
                  prefs.getInt('total_students')?.toString() ??
                  'N/A',
            };
          }
        } catch (e) {
          _routeInfo = {
            'routeName': prefs.getString('route_name') ?? 'Not Assigned',
            'totalStops': prefs.getInt('total_stops')?.toString() ?? 'N/A',
            'totalStudents':
                prefs.getInt('total_students')?.toString() ?? 'N/A',
          };
        }
      } else {
        _routeInfo = {
          'routeName': prefs.getString('route_name') ?? 'Not Assigned',
          'totalStops': prefs.getInt('total_stops')?.toString() ?? 'N/A',
          'totalStudents': prefs.getInt('total_students')?.toString() ?? 'N/A',
        };
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: CustomAppBar(
          title: 'My Profile',
          subtitle: 'Driver Information',
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryDriver,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 2.h),

                    // Modern header card with avatar + summary
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryDriver,
                              AppTheme.primaryDriver.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryDriver
                                  .withValues(alpha: 0.35),
                              offset: const Offset(0, 10),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.textOnPrimary,
                              ),
                              child: Center(
                                child: Text(
                                  (_driverInfo['name'] as String? ?? 'D')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDriver,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _driverInfo['name'] as String? ?? 'Driver',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textOnPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    'Driver ID: ${_driverInfo['id'] as String? ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textOnPrimary
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Wrap(
                                    spacing: 1.5.w,
                                    runSpacing: 0.5.h,
                                    children: [
                                      if (_busInfo != null)
                                        _buildChip(
                                          Icons.directions_bus,
                                          _busInfo?['busNumber'] as String? ??
                                              'No Bus',
                                        ),
                                      if (_routeInfo != null)
                                        _buildChip(
                                          Icons.route,
                                          _routeInfo?['routeName'] as String? ??
                                              'No Route',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 2.5.h),

                    // Quick stats row
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              label: 'Students',
                              value: _routeInfo?['totalStudents'] as String? ??
                                  '0',
                              icon: Icons.groups,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: _buildStatCard(
                              label: 'Stops',
                              value:
                                  _routeInfo?['totalStops'] as String? ?? '0',
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: _buildStatCard(
                              label: 'Bus Cap.',
                              value: _busInfo?['capacity'] as String? ?? 'N/A',
                              icon: Icons.airline_seat_recline_normal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Personal Information Section
                    _buildSection(
                      title: 'Personal Information',
                      icon: Icons.person,
                      children: [
                        _buildInfoRow(
                            'Email',
                            _driverInfo['email'] as String? ?? 'Not Available',
                            Icons.email),
                        _buildInfoRow(
                            'Phone',
                            _driverInfo['phone'] as String? ?? 'Not Available',
                            Icons.phone),
                        _buildInfoRow(
                            'License Number',
                            _driverInfo['licenseNumber'] as String? ??
                                'Not Available',
                            Icons.credit_card),
                        _buildInfoRow(
                            'License Expiry',
                            _driverInfo['licenseExpiry'] as String? ??
                                'Not Available',
                            Icons.event_available),
                        _buildInfoRow(
                            'National ID',
                            _driverInfo['nationalId'] as String? ??
                                'Not Available',
                            Icons.badge_outlined),
                        _buildInfoRow(
                            'Gender',
                            _driverInfo['gender'] as String? ?? 'Not Available',
                            Icons.person_outline),
                        _buildInfoRow(
                            'Date of Birth',
                            _driverInfo['dob'] as String? ?? 'Not Available',
                            Icons.cake_outlined),
                        _buildInfoRow(
                            'Address',
                            _driverInfo['address'] as String? ??
                                'Not Available',
                            Icons.home_outlined),
                        _buildInfoRow(
                            'Join Date',
                            _driverInfo['joinDate'] as String? ??
                                'Not Available',
                            Icons.calendar_today),
                      ],
                    ),

                    // Bus Assignment Section (always shown, with safe defaults)
                    _buildSection(
                      title: 'Bus Assignment',
                      icon: Icons.directions_bus,
                      children: [
                        _buildInfoRow(
                          'Bus Number',
                          (_busInfo?['busNumber'] as String?) ?? 'Not Assigned',
                          Icons.confirmation_number,
                        ),
                        _buildInfoRow(
                          'License Plate',
                          (_busInfo?['busPlate'] as String?) ?? 'N/A',
                          Icons.local_shipping,
                        ),
                        _buildInfoRow(
                          'Capacity',
                          (_busInfo?['capacity'] as String?) ?? 'N/A',
                          Icons.airline_seat_recline_normal,
                        ),
                      ],
                    ),

                    // Route Information Section
                    _buildSection(
                      title: 'Route Information',
                      icon: Icons.route,
                      children: [
                        _buildInfoRow(
                            'Route Name',
                            _routeInfo?['routeName'] as String? ??
                                'Not Assigned',
                            Icons.signpost),
                        _buildInfoRow(
                            'Total Stops',
                            _routeInfo?['totalStops'] as String? ?? 'N/A',
                            Icons.location_on),
                        _buildInfoRow(
                            'Total Students',
                            _routeInfo?['totalStudents'] as String? ?? 'N/A',
                            Icons.groups),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Edit Profile Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Edit profile feature coming soon'),
                              backgroundColor: AppTheme.primaryDriver,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDriver,
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
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 2.w),
                            Text(
                              'Edit Profile',
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
        bottomNavigationBar: CustomBottomBar(
          currentIndex: 2, // Profile tab
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/driver-start-shift-screen');
                break;
              case 1:
                Navigator.pushNamed(context, '/driver-active-trip-screen');
                break;
              case 2:
                // Already on profile screen
                break;
            }
          },
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
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: AppTheme.textOnPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textOnPrimary),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.8.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryDriver.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryDriver),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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
}
