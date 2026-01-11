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
        'name': prefs.getString('user_name') ?? 'Driver',
        'id': prefs.getInt('user_id')?.toString() ?? 'N/A',
        'email': prefs.getString('user_email') ?? 'Not Available',
        'phone': prefs.getString('user_phone') ?? 'Not Available',
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
                (children is List ? children.length : null);
            final totalStops = decoded['total_stops'] ??
                decoded['total_assignments'] ??
                (children is List ? children.length : null);

            _routeInfo = {
              'routeName': decoded['route_name']?.toString() ??
                  prefs.getString('route_name') ??
                  'Not Assigned',
              'totalStops': totalStops?.toString() ??
                  prefs.getInt('total_stops')?.toString() ??
                  'N/A',
              'totalStudents': totalChildren?.toString() ??
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
                    SizedBox(height: 3.h),

                    // Profile Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryDriver,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primaryDriver.withValues(alpha: 0.3),
                            offset: Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (_driverInfo['name'] as String? ?? 'D')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textOnPrimary,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Driver Name
                    Text(
                      _driverInfo['name'] as String? ?? 'Driver',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    SizedBox(height: 0.5.h),

                    // Driver ID
                    Text(
                      'Driver ID: ${_driverInfo['id'] as String? ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 4.h),

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
