import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/home_location_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/cache_service.dart';
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
  final AuthService _authService = AuthService();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isLoading = true;

  // Parent data from API
  User? _user;
  Parent? _parent;
  List<Child> _children = [];

  @override
  void initState() {
    super.initState();
    // Load profile data immediately from cache
    _loadProfileData();

    // Defer connectivity initialization
    Future.microtask(() {
      _initializeConnectivity();
    });
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    _connectivityService.onConnectionRestored = () {
      if (mounted) {
        // Don't show toast on profile page, home dashboard handles it
        _loadProfileData(forceRefresh: true);
      }
    };
    _connectivityService.onConnectionLost = () {
      if (mounted) {
        _showToast('Currently offline', isError: true);
      }
    };
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

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFFF9500) : const Color(0xFF34C759),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadProfileData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // First, try to load from cache immediately (without showing loading)
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final cachedFirstName = prefs.getString('parent_first_name') ?? '';
      final cachedLastName = prefs.getString('parent_last_name') ?? '';
      final cachedEmail = prefs.getString('parent_email') ?? '';
      final userId = prefs.getInt('user_id') ?? 0;

      // Also load cached children
      final cacheService = CacheService();
      final cachedChildren = await cacheService.getStaleChildren();

      if (cachedFirstName.isNotEmpty || cachedEmail.isNotEmpty) {
        setState(() {
          _user = User(
            id: userId,
            username: cachedEmail,
            email: cachedEmail,
            firstName: cachedFirstName,
            lastName: cachedLastName,
          );
          // Load cached children
          if (cachedChildren != null && cachedChildren.isNotEmpty) {
            _children =
                cachedChildren.map((json) => Child.fromJson(json)).toList();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = true;
        });
      }
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Clear cache if force refreshing to ensure fresh data
      if (forceRefresh) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('dashboard_data');
        await prefs.remove('dashboard_timestamp');
      }

      // Load parent profile data with timeout
      final parentProfile = await _apiService.getParentProfile().timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Currently offline'),
          );

      // Load children data separately (same as home dashboard) with timeout
      final children = await _apiService.getMyChildren().timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Currently offline'),
          );

      if (mounted) {
        setState(() {
          // Extract user data from parent profile
          final userData = parentProfile['user'];

          if (userData != null && userData['id'] != null) {
            _user = User(
              id: userData['id'],
              username: userData['email'] ?? '',
              email: userData['email'] ?? '',
              firstName: userData['first_name'] ?? '',
              lastName: userData['last_name'] ?? '',
            );

            // Extract parent data
            final parentData = parentProfile['parent'];
            _parent = Parent(
              userId: userData['id'],
              contactNumber: parentData['contact_number'] ?? '',
              address: parentData['address'] ?? '',
              emergencyContact: parentData['emergency_contact'] ?? '',
              status: parentData['status'] ?? 'active',
            );
          }

          // Set children data (same as home dashboard)
          _children = children;

          _isLoading = false;
        });
      }

      // Also refresh the dashboard when profile is refreshed
      widget.onRefreshDashboard?.call();
    } catch (e) {
      // Try to get cached/existing user data as fallback
      if (mounted && _user == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final firstName = prefs.getString('parent_first_name') ?? '';
          final lastName = prefs.getString('parent_last_name') ?? '';
          final email = prefs.getString('parent_email') ?? '';
          final userId = prefs.getInt('user_id') ?? 0;

          if (firstName.isNotEmpty || email.isNotEmpty) {
            setState(() {
              _user = User(
                id: userId,
                username: email,
                email: email,
                firstName: firstName,
                lastName: lastName,
              );
            });
          }
        } catch (_) {}

        setState(() {
          _isLoading = false;
        });

        // Show appropriate offline message
        String errorMsg = e.toString().contains('offline') ||
                e.toString().contains('TimeoutException') ||
                e.toString().contains('SocketException')
            ? 'Currently offline'
            : e.toString().replaceAll('Exception: ', '');

        _showToast(errorMsg, isError: true);
      }
    }
  }

  // Public method to refresh data from parent widget
  void refreshData({bool forceRefresh = false}) {
    _loadProfileData(forceRefresh: forceRefresh);
  }

  // Get parent name from cached data as fallback
  Future<String> _getParentNameFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('parent_first_name') ?? '';
      final lastName = prefs.getString('parent_last_name') ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    } catch (_) {}
    return 'Parent';
  }

  @override
  Widget build(BuildContext context) {
    // Cache theme lookups
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Don't show loading if we have user data (even if it's from cache)
    final bool showLoading = _isLoading && _user == null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile & Settings',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: showLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadProfileData(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header - Compact horizontal layout
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 7.w,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                            child: Text(
                              _user?.fullName.isNotEmpty == true
                                  ? _user!.fullName.substring(0, 1).toUpperCase()
                                  : 'P',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.fullName ?? 'Parent',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 0.4.h),
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                                    SizedBox(width: 1.w),
                                    Expanded(
                                      child: Text(
                                        _user?.email ?? '',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_parent?.contactNumber.isNotEmpty == true) ...[
                                  SizedBox(height: 0.3.h),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                                      SizedBox(width: 1.w),
                                      Text(
                                        _parent!.contactNumber,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.5.h),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: colorScheme.primary,
                              size: 4.5.w,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Home Location',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                SizedBox(height: 0.4.h),
                                Text(
                                  _cleanAddress(_parent?.address),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
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
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () => _showUpdateAddressDialog(),
                              icon: Icon(
                                Icons.edit_rounded,
                                color: colorScheme.primary,
                                size: 5.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.5.h),

                    // Children Information Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Children',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.8.h),

                    // Children Cards
                    if (_children.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'No children registered',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                'Contact your school admin to add children to your account',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._children
                          .map((child) => RepaintBoundary(
                                child: ChildInformationWidget(
                                  childData: _childToCardData(child),
                                ),
                              ))
                          .toList(),

                    SizedBox(height: 2.5.h),

                    // App Settings Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Settings',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.8.h),

                    // Dark Mode Toggle
                    RepaintBoundary(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 0.5.h),
                        padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.dark_mode_rounded,
                                color: colorScheme.primary,
                                size: 4.5.w,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dark Mode',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 0.3.h),
                                  Text(
                                    'Enable dark theme',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
                    ),

                    SizedBox(height: 0.5.h),

                    // "Dark mode coming soon" message removed - it's working now!

                    // Privacy Policy and Terms & Conditions
                    RepaintBoundary(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 0.5.h),
                        padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 0.h),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => _openPrivacyPolicy(),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.privacy_tip_outlined,
                                        color: colorScheme.primary,
                                        size: 4.5.w,
                                      ),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Text(
                                        'Privacy Policy',
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                            InkWell(
                              onTap: () => _openTermsAndConditions(),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.description_outlined,
                                        color: colorScheme.primary,
                                        size: 4.5.w,
                                      ),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Text(
                                        'Terms & Conditions',
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 1.5.h),

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
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 6.h), // Space for bottom navigation
                  ],
                ),
              ),
            ),
    );
  }

  Map<String, dynamic> _childToCardData(Child child) {
    return {
      "id": child.id,
      "name": child.fullName,
      "grade": child.classGrade,
      "childId": "AB${child.id}",
      "class": child.classGrade,
      "homeAddress": _parent?.address ?? 'Not set',
      "status": child.currentStatus ?? 'no record today',
      "busId": child.assignedBus?.id,
      "busNumber": child.assignedBus?.numberPlate,
    };
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

          // Build final address with meaningful parts.
          // Require at least 2 parts (e.g. "Westlands, Nairobi") - a single
          // city name like "Nairobi" is too vague to be a useful home address.
          if (uniqueParts.length > 1) {
            locationAddress = uniqueParts.join(', ');
          } else {
            // Single word or empty - geocoding was city-level only.
            // Use GPS coordinates which the map can use precisely.
            locationAddress =
                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
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

    // Cache theme for dialog
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_location_rounded,
                      color: colorScheme.primary,
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
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          'Change your home location',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 3.5.w,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: 1.5.w),
                        Text(
                          'Best accuracy with GPS',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
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
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          'OR',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 1.5.h),

                  // Manual address input
                  Text(
                    'Type address manually',
                    style: textTheme.bodySmall?.copyWith(
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
    // Cache theme for dialog
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF3B30),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: textTheme.bodyMedium,
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

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://www.apobasi.com/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTermsAndConditions() async {
    final uri = Uri.parse('https://www.apobasi.com/terms');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}
