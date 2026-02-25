import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
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
      final cachedPhone = prefs.getString('parent_phone') ?? '';
      final cachedAddress = prefs.getString('parent_address') ?? '';
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
          _parent = Parent(
            userId: userId,
            contactNumber: cachedPhone,
            address: cachedAddress,
            emergencyContact: '',
            status: 'active',
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

      // Cache fresh parent data for offline use
      final cachePrefs = await SharedPreferences.getInstance();
      await cachePrefs.setString('parent_first_name', _user?.firstName ?? '');
      await cachePrefs.setString('parent_last_name', _user?.lastName ?? '');
      await cachePrefs.setString('parent_email', _user?.email ?? '');
      await cachePrefs.setString('parent_phone', _parent?.contactNumber ?? '');
      await cachePrefs.setString('parent_address', _parent?.address ?? '');

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
          final phone = prefs.getString('parent_phone') ?? '';
          final address = prefs.getString('parent_address') ?? '';
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
              _parent = Parent(
                userId: userId,
                contactNumber: phone,
                address: address,
                emergencyContact: '',
                status: 'active',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool showLoading = _isLoading && _user == null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
                    Divider(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.3)),

                    // ── Profile header ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(
                        children: [
                          // Large avatar
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.primary
                                      .withValues(alpha: 0.15)
                                  : const Color(0xFFF9E4F1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _user?.fullName.isNotEmpty == true
                                    ? _user!.fullName[0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Name, email, phone
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.fullName ?? 'Parent',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (_user?.email != null &&
                                    _user!.email.isNotEmpty)
                                  Text(
                                    _user!.email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (_parent?.contactNumber.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _parent!.contactNumber,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Edit pencil
                          GestureDetector(
                            onTap: () => _showUpdateAddressDialog(),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Children section ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'Children',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),

                    if (_children.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Text(
                          'No children registered. Contact your school admin.',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ..._children
                          .map((child) => ChildInformationWidget(
                                childData: _childToCardData(child),
                              ))
                          .toList(),

                    const SizedBox(height: 20),

                    // ── Settings section ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),

                    // Settings grouped card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outline,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Notification Preferences
                          _buildSwitchRow(
                            label: 'Notification Preferences',
                            value: true, // TODO: connect to actual preference
                            onChanged: (val) {
                              // TODO: toggle notification preferences
                            },
                            colorScheme: colorScheme,
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color:
                                colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          // Dark Mode
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: _themeService.themeModeNotifier,
                            builder: (context, themeMode, child) {
                              return _buildSwitchRow(
                                label: 'Dark Mode',
                                value: themeMode == ThemeMode.dark,
                                onChanged: (val) {
                                  _themeService.setThemeMode(
                                    val ? ThemeMode.dark : ThemeMode.light,
                                  );
                                },
                                colorScheme: colorScheme,
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color:
                                colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          // Home Location
                          _buildNavRow(
                            label: 'Home',
                            onTap: () => _showUpdateAddressDialog(),
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Account section ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'Account',
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
                        border: Border.all(
                          color: colorScheme.outline,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildNavRow(
                            label: 'Privacy Policy',
                            onTap: () => _openPrivacyPolicy(),
                            colorScheme: colorScheme,
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color:
                                colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          _buildNavRow(
                            label: 'Terms of Service',
                            onTap: () => _openTermsAndConditions(),
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Logout ──────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => _showLogoutDialog(),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
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
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 4),
            ],
            Icon(
              Icons.chevron_right,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            ),
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
      "childId": "AB${child.id}",
      "class": child.classGrade,
      "homeAddress": _parent?.address ?? 'Not set',
      "status": child.currentStatus ?? 'no record today',
      "busId": child.assignedBus?.id,
      "busNumber": child.assignedBus?.numberPlate,
    };
  }

  // ── Location helpers ────────────────────────────────────────────────────

  bool _ok(String? s) {
    if (s == null || s.length < 3) return false;
    if (RegExp(r'^\d+$').hasMatch(s)) return false;
    if (RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}$').hasMatch(s.trim()))
      return false;
    return true;
  }

  /// Builds the best human-readable address from a Placemark.
  /// Order: street number + street/road → neighbourhood → city → country
  ///
  /// On Android `name` often carries the specific location (e.g. "Riverside")
  /// when thoroughfare / subLocality are empty — common in East Africa.
  String _buildReadableAddress(Placemark p) {
    final parts = <String>[];

    // Try to build street address with number
    String? streetAddress;
    if (_ok(p.subThoroughfare) && _ok(p.thoroughfare)) {
      // e.g. "104" + "Riverside Drive" = "104 Riverside Drive"
      streetAddress = '${p.subThoroughfare} ${p.thoroughfare}';
    } else if (_ok(p.thoroughfare)) {
      streetAddress = p.thoroughfare;
    } else if (_ok(p.street)) {
      streetAddress = p.street;
    } else if (_ok(p.name) &&
        p.name != p.locality &&
        p.name != p.country &&
        p.name != p.administrativeArea &&
        p.name != p.subAdministrativeArea &&
        p.name != p.subLocality) {
      streetAddress = p.name;
    }

    if (streetAddress != null) parts.add(streetAddress);

    // Neighbourhood: try multiple fields for area-level detail
    if (_ok(p.subLocality)) {
      parts.add(p.subLocality!);
    } else if (_ok(p.subAdministrativeArea) &&
        p.subAdministrativeArea != p.locality) {
      parts.add(p.subAdministrativeArea!);
    }

    // City/locality
    if (_ok(p.locality)) {
      parts.add(p.locality!);
    } else if (_ok(p.administrativeArea)) {
      parts.add(p.administrativeArea!);
    }

    // Only add country if we don't have enough detail
    if (parts.length < 2 && _ok(p.country)) {
      parts.add(p.country!);
    }

    // Deduplicate (case-insensitive)
    final seen = <String>{};
    final unique = parts.where((s) => seen.add(s.toLowerCase())).toList();
    return unique.join(', ');
  }

  /// Fallback: native platform geocoder.
  Future<String?> _nativeGeocode(Position position) async {
    try {
      final marks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (marks.isEmpty) return null;

      // Try all placemarks to find the most detailed one
      String? bestAddress;
      int maxParts = 0;

      for (final mark in marks) {
        final built = _buildReadableAddress(mark);
        if (built.isNotEmpty) {
          final parts = built.split(',').length;
          if (parts > maxParts) {
            maxParts = parts;
            bestAddress = built;
          }
        }
      }

      return bestAddress;
    } catch (_) {
      return null;
    }
  }

  /// Reverse-geocodes [lat]/[lon] via the Mapbox Geocoding API.
  /// Returns a human-readable address string, or null on failure.
  /// Mapbox has far better East Africa street coverage than the native geocoder.
  Future<String?> _reverseGeocodeMapbox(double lat, double lon) async {
    try {
      final token = ApiConfig.mapboxAccessToken;
      if (token.isEmpty) return null;

      // Strategy 1: Get ALL nearby features to find the most specific address
      var uri = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json'
        '?access_token=$token&types=address,poi&limit=5&language=en',
      );
      var response = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          // Try each feature, preferring those with address numbers
          for (final feature in features) {
            final featureMap = feature as Map<String, dynamic>;
            final address =
                _parseMapboxFeature(featureMap, preferDetailed: true);
            if (address != null && address.isNotEmpty) {
              // Check if it has a street number (indicates precise address)
              if (RegExp(r'^\d+').hasMatch(address) ||
                  address.split(',').length >= 3) {
                return address;
              }
            }
          }
          // If no detailed address found, use the first result
          final address =
              _parseMapboxFeature(features.first as Map<String, dynamic>);
          if (address != null && address.isNotEmpty) return address;
        }
      }

      // Strategy 2: Try with neighborhood to get area name
      uri = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json'
        '?access_token=$token&types=neighborhood,locality&limit=3&language=en',
      );
      response = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final feature = features.first as Map<String, dynamic>;
          return _parseMapboxFeature(feature);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parses a Mapbox feature into a readable address
  String? _parseMapboxFeature(Map<String, dynamic> feature,
      {bool preferDetailed = false}) {
    final placeName = feature['place_name'] as String? ?? '';
    final text = feature['text'] as String? ?? '';
    final address = feature['address'] as String? ?? '';
    final placeType = (feature['place_type'] as List?)?.cast<String>() ?? [];
    final context =
        (feature['context'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};

    String streetNumber = '';
    String street = '';
    String suburb = '';
    String city = '';

    // Extract street number/address number if available
    if (address.isNotEmpty) {
      streetNumber = address;
    }

    // For address type, combine street number + street name
    if (placeType.contains('address')) {
      if (streetNumber.isNotEmpty && text.isNotEmpty) {
        street = '$streetNumber $text';
      } else if (text.isNotEmpty) {
        street = text;
      } else if (placeName.isNotEmpty) {
        // Use place_name which often contains full street address
        final parts = placeName.split(',').map((s) => s.trim()).toList();
        if (parts.isNotEmpty) street = parts.first;
      }
    } else if (placeType.contains('poi')) {
      // For POI, use the POI name as the street/location
      street = text;
    } else if (placeType.contains('neighborhood') ||
        placeType.contains('locality')) {
      suburb = text;
    }

    // Extract suburb and city from context
    for (final c in context) {
      final id = c['id'] as String? ?? '';
      final contextText = c['text'] as String? ?? '';

      if (id.startsWith('neighborhood') && suburb.isEmpty) {
        suburb = contextText;
      } else if (id.startsWith('locality') &&
          suburb.isEmpty &&
          !placeType.contains('locality')) {
        suburb = contextText;
      } else if (id.startsWith('place') && city.isEmpty) {
        city = contextText;
      }
    }

    // Build address from parts, removing duplicates
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (city.isNotEmpty) parts.add(city);

    // Deduplicate (case-insensitive)
    final seen = <String>{};
    final unique = parts.where((s) => seen.add(s.toLowerCase())).toList();

    return unique.isEmpty ? null : unique.join(', ');
  }

  /// Detects the current GPS position and reverse-geocodes it to a readable
  /// address. Returns null and toasts on failure.
  Future<({Position position, String address})?> _detectGpsLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showToast('Please enable location services on your device', isError: true);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      _showToast('Location permission permanently denied — enable it in Settings', isError: true);
      return null;
    }
    if (permission == LocationPermission.denied) {
      _showToast('Location permission is required to detect your address', isError: true);
      return null;
    }
    try {
      // Use high accuracy for better street-level precision
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      // Try Mapbox first (has better East Africa street data),
      // then native geocoder, finally raw coordinates as last resort
      String? address =
          await _reverseGeocodeMapbox(position.latitude, position.longitude);

      if (address == null || address.isEmpty) {
        address = await _nativeGeocode(position);
      }

      if (address == null || address.isEmpty) {
        address =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      }

      return (position: position, address: address);
    } catch (e) {
      _showToast(
        'Could not get location: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
      return null;
    }
  }

  void _showUpdateAddressDialog() {
    final addressController =
        TextEditingController(text: _parent?.address ?? '');

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // GPS position captured when parent taps "Detect my location".
    // Stored so we save actual GPS coords rather than re-geocoding the text.
    Position? gpsPosition;
    bool detecting = false;

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
                  // ── GPS button — stays in dialog, fills text field ──────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: detecting
                          ? null
                          : () async {
                              setDialogState(() => detecting = true);
                              final result = await _detectGpsLocation();
                              if (!context.mounted) return;
                              if (result != null) {
                                gpsPosition = result.position;
                                addressController.text = result.address;

                                // Check if address is too generic (just city or coordinates)
                                final hasComma = result.address.contains(',');
                                final isCoordinates =
                                    result.address.contains('.');
                                final parts = result.address
                                    .split(',')
                                    .map((e) => e.trim())
                                    .toList();

                                if (isCoordinates ||
                                    (!hasComma) ||
                                    parts.length == 1) {
                                  _showToast(
                                    'Please add your street name or area for accuracy',
                                    isError: true,
                                  );
                                } else if (parts.length == 2) {
                                  _showToast(
                                    'Location detected. Please verify or add more details',
                                    isError: false,
                                  );
                                } else {
                                  _showToast(
                                    'Location detected successfully',
                                    isError: false,
                                  );
                                }
                              }
                              setDialogState(() => detecting = false);
                            },
                      icon: detecting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.my_location, size: 4.5.w),
                      label: Text(
                        detecting ? 'Detecting…' : 'Detect my location',
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

                  // ── Address text field ───────────────────────────────────
                  Text(
                    'Confirm or type address',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    style: TextStyle(fontSize: 13.sp),
                    decoration: InputDecoration(
                      hintText: 'e.g. Ngong Road, Karen, Nairobi',
                      hintStyle: TextStyle(
                          fontSize: 11.sp, color: colorScheme.onSurfaceVariant),
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
                  child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
                ),
                FilledButton(
                  onPressed: () async {
                    final newAddress = addressController.text.trim();
                    if (newAddress.isEmpty) {
                      _showToast('Please enter an address', isError: true);
                      return;
                    }
                    try {
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      // If parent used GPS, we already have precise coordinates.
                      // Otherwise geocode the typed address for coordinates.
                      if (gpsPosition != null) {
                        await _homeLocationService.clearHomeLocation();
                        await _homeLocationService.setHomeLocation(
                          latitude: gpsPosition!.latitude,
                          longitude: gpsPosition!.longitude,
                          address: newAddress,
                        );
                      } else {
                        await _homeLocationService
                            .setHomeLocationFromAddress(newAddress);
                      }

                      await _apiService.updateParentProfile(
                          address: newAddress);

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
                        Navigator.of(context).pop(); // close loading
                        Navigator.of(context).pop(); // close dialog
                        _showToast('Home location updated');
                      }
                    } catch (e) {
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      _showToast(
                        'Failed: ${e.toString().replaceAll('Exception: ', '')}',
                        isError: true,
                      );
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
                    'Save location',
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
