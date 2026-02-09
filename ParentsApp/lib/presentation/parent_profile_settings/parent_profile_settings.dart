import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/home_location_service.dart';
import '../../models/child_model.dart';
import '../../models/parent_model.dart';
import './widgets/child_information_widget.dart';

class ParentProfileSettings extends StatefulWidget {
  final VoidCallback? onRefreshDashboard;

  const ParentProfileSettings({
    Key? key,
    this.onRefreshDashboard,
  }) : super(key: key);

  @override
  State<ParentProfileSettings> createState() => _ParentProfileSettingsState();
}

class _ParentProfileSettingsState extends State<ParentProfileSettings> {
  final ApiService _apiService = ApiService();
  final ThemeService _themeService = ThemeService();
  final HomeLocationService _homeLocationService = HomeLocationService();
  bool _isLoading = true;
  String? _error;

  // Parent data from API
  User? _user;
  Parent? _parent;
  List<Child> _children = [];

  @override
  void initState() {
    super.initState();
    // Defer data loading to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  // Helper to clean up address formatting (remove double commas, extra spaces)
  String _cleanAddress(String? address) {
    if (address == null || address.isEmpty) return 'Address not set';

    // Remove multiple consecutive commas and spaces
    return address
        .replaceAll(RegExp(r',\s*,+'), ',') // Replace ", ," with ","
        .replaceAll(
            RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r',\s+,'), ',') // Replace ", ," with ","
        .trim();
  }

  Future<void> _loadProfileData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use consolidated dashboard API endpoint - single call for all data
      final dashboardData = await _apiService.getDashboardData(
        forceRefresh: forceRefresh,
      );

      setState(() {
        // Extract parent data
        final parentData = dashboardData['parent'];
        if (parentData != null) {
          _user = User(
            id: parentData['id'],
            username: parentData['email'] ?? '',
            email: parentData['email'] ?? '',
            firstName: parentData['firstName'] ?? '',
            lastName: parentData['lastName'] ?? '',
          );

          _parent = Parent(
            userId: parentData['id'],
            contactNumber: parentData['phone'] ?? '',
            address: parentData['address'] ?? '',
            emergencyContact: parentData['emergencyContact'] ?? '',
            status: parentData['status'] ?? 'active',
          );
        }

        // Extract children data and convert to Child objects
        final childrenJson = dashboardData['children'] as List<dynamic>?;
        if (childrenJson != null && childrenJson.isNotEmpty) {
          _children = childrenJson.map((json) => Child.fromJson(json)).toList();
        } else {
          _children = [];
        }

        _isLoading = false;
      });

      // Also refresh the dashboard when profile is refreshed
      widget.onRefreshDashboard?.call();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Public method to refresh data from parent widget
  void refreshData({bool forceRefresh = false}) {
    _loadProfileData(forceRefresh: forceRefresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile & Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _loadProfileData(forceRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 0),
                      child: Container(
                        padding: EdgeInsets.all(2.5.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 4.w,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Profile Header - Sleeker Design
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                    margin: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05),
                          Theme.of(context).colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 11.w,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            child: Text(
                              _user?.fullName.substring(0, 1).toUpperCase() ??
                                  'P',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: 1.8.h),
                        Text(
                          _user?.fullName ?? 'Parent Name',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                        ),
                        SizedBox(height: 0.8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 1.5.w),
                              Text(
                                _user?.email ?? 'email@example.com',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 1.5.w),
                              Text(
                                _parent?.contactNumber ?? 'N/A',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Home Location Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      'Home Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.5.w),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.8.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15),
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 5.5.w,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Address',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.sp,
                                    ),
                              ),
                              SizedBox(height: 0.4.h),
                              Text(
                                _cleanAddress(_parent?.address),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => _showUpdateAddressDialog(),
                            icon: Icon(
                              Icons.edit_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 5.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Children Information Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      'Children Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Children Cards
                  ..._children
                      .map((child) => ChildInformationWidget(
                            childData: _childToCardData(child),
                          ))
                      .toList(),

                  SizedBox(height: 4.h),

                  // App Settings Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Dark Mode Toggle
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    padding: EdgeInsets.all(3.5.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.8.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15),
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.dark_mode_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 5.5.w,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                'Enable dark theme',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 10.sp,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: _themeService.themeModeNotifier,
                          builder: (context, themeMode, child) {
                            return Switch(
                              value: themeMode == ThemeMode.dark,
                              onChanged: (value) {
                                _themeService.setThemeMode(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 0.5.h),

                  // "Dark mode coming soon" message removed - it's working now!

                  SizedBox(height: 1.h),

                  // Privacy Policy and Terms & Conditions
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    padding: EdgeInsets.all(3.5.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _openPrivacyPolicy(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2.8.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15),
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.privacy_tip_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 5.5.w,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    'Privacy Policy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.1),
                        ),
                        InkWell(
                          onTap: () => _openTermsAndConditions(),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(2.8.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.15),
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.08),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 5.5.w,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    'Terms & Conditions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 5.w),
                          SizedBox(width: 2.w),
                          Text(
                            'Logout',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h), // Space for bottom navigation
                ],
              ),
            ),
    );
  }

  Map<String, dynamic> _childToCardData(Child child) {
    return {
      "id": child.id,
      "name": child.fullName,
      "grade": child.classGrade,
      "school": "School Name", // TODO: Add school name to backend
      "studentId": "STU${child.id}",
      "class": child.classGrade,
      "homeAddress": _parent?.address ?? 'Not set',
      "status": child.currentStatus ?? 'no record today',
      "busId": child.assignedBus?.id,
      "busNumber": child.assignedBus?.numberPlate,
    };
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 2.h),
            Text(
              'Error Loading Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: () => _loadProfileData(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
        return;
      }

      // Get current position with high accuracy and timeout
      // This waits for GPS to acquire a good satellite fix
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      // Check if accuracy is good enough (less than 50 meters)
      if (position.accuracy > 50) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Low GPS Accuracy'),
            content: Text(
              'GPS accuracy is ${position.accuracy.toStringAsFixed(0)}m.\n\n'
              'For best results:\n'
              '• Go outside or near a window\n'
              '• Wait a few seconds for GPS to lock\n'
              '• Try again\n\n'
              'Or manually enter your address instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _useCurrentLocation(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        return;
      }

      // Use reverse geocoding to get human-readable address
      String locationAddress;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;

          // Build a more user-friendly address with actual place names
          final addressParts = <String>[];

          // Helper function to check if string is a Plus Code (e.g., PQJR+H4F)
          bool isPlusCode(String text) {
            return RegExp(r'^[A-Z0-9]{4}\+[A-Z0-9]{2,3}$')
                .hasMatch(text.trim());
          }

          // Helper function to check if string is meaningful (not just numbers or codes)
          bool isMeaningfulName(String? text) {
            if (text == null || text.isEmpty) return false;
            // Reject pure numbers, Plus Codes, and very short strings
            if (text.contains(RegExp(r'^\d+$'))) return false;
            if (isPlusCode(text)) return false;
            if (text.length < 3) return false;
            return true;
          }

          // Prioritize street name over generic name
          if (isMeaningfulName(placemark.street)) {
            addressParts.add(placemark.street!);
          }

          // Add subLocality for neighborhood/area (e.g., "Westlands", "Kilimani")
          if (isMeaningfulName(placemark.subLocality) &&
              !addressParts.contains(placemark.subLocality)) {
            addressParts.add(placemark.subLocality!);
          }

          // Add thoroughfare (main road name) if available and different
          if (isMeaningfulName(placemark.thoroughfare) &&
              !addressParts.contains(placemark.thoroughfare) &&
              placemark.thoroughfare != placemark.street) {
            addressParts.add(placemark.thoroughfare!);
          }

          // Add locality (city/town - e.g., "Nairobi")
          if (isMeaningfulName(placemark.locality) &&
              !addressParts.contains(placemark.locality)) {
            addressParts.add(placemark.locality!);
          }

          // Only add name if it's meaningful and not already included
          if (isMeaningfulName(placemark.name) &&
              !addressParts.contains(placemark.name)) {
            addressParts.add(placemark.name!);
          }

          // Remove duplicates and filter out Plus Codes from final address
          final uniqueParts = <String>[];
          for (final part in addressParts) {
            // Skip Plus Codes in final address
            if (isPlusCode(part)) continue;

            // Check for duplicates (case-insensitive, substring match)
            bool isDuplicate = uniqueParts.any((existing) =>
                existing.toLowerCase() == part.toLowerCase() ||
                existing.toLowerCase().contains(part.toLowerCase()) ||
                part.toLowerCase().contains(existing.toLowerCase()));

            if (!isDuplicate) {
              uniqueParts.add(part);
            }
          }

          // Build final address with meaningful parts
          if (uniqueParts.isNotEmpty) {
            locationAddress = uniqueParts.join(', ');
          } else {
            // Fallback: Try to construct from administrative areas
            final fallbackParts = <String>[];
            if (isMeaningfulName(placemark.administrativeArea)) {
              fallbackParts.add(placemark.administrativeArea!);
            }
            if (isMeaningfulName(placemark.locality)) {
              fallbackParts.add(placemark.locality!);
            }

            locationAddress = fallbackParts.isNotEmpty
                ? fallbackParts.join(', ')
                : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          }
        } else {
          locationAddress =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        // Fallback to coordinates if geocoding fails
        locationAddress =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }

      // FIRST: Clear old cached coordinates
      await _homeLocationService.clearHomeLocation();

      // SECOND: Save fresh GPS coordinates to cache
      await _homeLocationService.setHomeLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: locationAddress,
      );

      // THIRD: Update on server
      await _apiService.updateParentProfile(
        address: locationAddress,
      );

      setState(() {
        _parent = Parent(
          userId: _parent!.userId,
          contactNumber: _parent!.contactNumber,
          address: locationAddress,
          emergencyContact: _parent!.emergencyContact,
          status: _parent!.status,
        );
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Home Location Updated successfully'),
          backgroundColor: Color(0xFF34C759),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  void _showUpdateAddressDialog() {
    final TextEditingController addressController =
        TextEditingController(text: _parent?.address ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0.5.h),
              contentPadding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.5.h),
              title: Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_location_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update home address',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.sp,
                                  ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          'Change your home location',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 11.sp,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // GPS accuracy badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w, vertical: 0.6.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 3.5.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 1.5.w),
                        Text(
                          'Best accuracy with GPS',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.sp,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.5.h),

                  // Use Current Location button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _useCurrentLocation();
                      },
                      icon: Icon(Icons.my_location, size: 4.5.w),
                      label: Text(
                        'Use current location',
                        style: TextStyle(
                            fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 1.5.h),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          'OR',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.sp,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.5.h),

                  // Manual address input
                  Text(
                    'Type address manually',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                  ),
                  SizedBox(height: 0.8.h),
                  TextField(
                    controller: addressController,
                    maxLines: 1,
                    style: TextStyle(fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: 'Enter your address',
                      hintStyle: TextStyle(fontSize: 12.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.2.h,
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
              actionsPadding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 1.5.h),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      final newAddress = addressController.text.trim();

                      if (newAddress.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an address'),
                            backgroundColor: Color(0xFFFF3B30),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      // Geocode the address FIRST to get coordinates
                      bool geocodeSuccess = false;
                      if (newAddress.isNotEmpty) {
                        geocodeSuccess = await _homeLocationService
                            .setHomeLocationFromAddress(newAddress);
                      }

                      // Save to backend
                      await _apiService.updateParentProfile(
                        address: newAddress,
                      );

                      if (mounted) {
                        setState(() {
                          _parent = Parent(
                            userId: _parent!.userId,
                            contactNumber: _parent!.contactNumber,
                            address: newAddress,
                            emergencyContact: _parent!.emergencyContact,
                            status: _parent!.status,
                          );
                        });

                        Navigator.of(context).pop(); // Close loading
                        Navigator.of(context).pop(); // Close dialog

                        if (geocodeSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('✓ Home location updated successfully'),
                              backgroundColor: Color(0xFF34C759),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Address saved but coordinates not found.\nUse GPS for better accuracy.',
                              ),
                              backgroundColor: Color(0xFFFF9500),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Close loading if still open
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      // Close dialog if still open
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Failed to update: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: const Color(0xFFFF3B30),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Update',
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF3B30),
                ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save navigator reference before async operations
                final navigator = Navigator.of(context);

                // Close the logout dialog first
                navigator.pop();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (buildContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Clear all authentication data
                await AuthService().signOut();

                // Close loading dialog and navigate using saved navigator
                navigator.pop(); // Close loading
                navigator.pushNamedAndRemoveUntil(
                  '/parent-login-screen',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _openPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Privacy Policy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Your privacy is important to us. This app collects and processes:\n\n'
              '• Child location data for safety and tracking\n'
              '• Parent contact information\n'
              '• School and bus assignment details\n\n'
              'Data is used solely for:\n'
              '• Real-time student tracking\n'
              '• Parent notifications\n'
              '• School safety compliance\n\n'
              'We do not share your data with third parties without consent.\n\n'
              'For questions, contact your school administrator.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Terms & Conditions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'By using this app, you agree to:\n\n'
              '1. Provide accurate information\n'
              '2. Use the app for legitimate school-related purposes only\n'
              '3. Not attempt to access unauthorized data\n'
              '4. Report any security concerns immediately\n\n'
              'The app is provided "as is" without warranties.\n\n'
              'School administration reserves the right to:\n'
              '• Monitor app usage\n'
              '• Suspend accounts for misuse\n'
              '• Update terms as needed\n\n'
              'Continued use indicates acceptance of these terms.\n\n'
              'For support, contact your school administrator.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
