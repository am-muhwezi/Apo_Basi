import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

import '../../../services/home_location_service.dart';
import '../../../services/api_service.dart';
import '../../../config/api_config.dart';

class HomeLocationPromptDialog extends StatefulWidget {
  final VoidCallback onLocationSet;

  const HomeLocationPromptDialog({
    Key? key,
    required this.onLocationSet,
  }) : super(key: key);

  @override
  State<HomeLocationPromptDialog> createState() =>
      _HomeLocationPromptDialogState();
}

class _HomeLocationPromptDialogState extends State<HomeLocationPromptDialog> {
  final HomeLocationService _homeLocationService = HomeLocationService();
  final ApiService _apiService = ApiService();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isManualEntry = false;
  String? _detectedAddress;
  Position? _detectedPosition;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Don't auto-detect location to avoid triggering Geolocator service
    // User can manually trigger it if needed
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permission denied. Please enable it in Settings.';
          _isManualEntry = true;
          _isLoading = false;
        });
        return;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Use Mapbox geocoding for detailed addresses (better East Africa coverage)
      String? address = await _reverseGeocodeMapbox(
        position.latitude,
        position.longitude,
      );

      // If geocoding fails, let user type address manually
      if (address == null || address.isEmpty) {
        setState(() {
          _detectedPosition = position;
          _error = 'Could not detect address. Please type your address below.';
          _isManualEntry = true;
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _detectedPosition = position;
          _detectedAddress = address;
          _addressController.text = address;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not detect location: ${e.toString().replaceAll('Exception: ', '')}';
          _isManualEntry = true;
          _isLoading = false;
        });
      }
    }
  }

  /// Reverse geocode using Mapbox API (better East Africa street data)
  Future<String?> _reverseGeocodeMapbox(double lat, double lon) async {
    try {
      final token = ApiConfig.mapboxAccessToken;
      if (token.isEmpty) {
        return null;
      }

      // Get detailed address - omit types to get most relevant result
      // Mapbox will return the best match (address, poi, place, etc.)
      var uri = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json'
        '?access_token=$token&limit=1&language=en',
      );
      
      var response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List?;
        
        if (features != null && features.isNotEmpty) {
          // Try to find the most detailed address
          for (final feature in features) {
            final featureMap = feature as Map<String, dynamic>;
            final address = _parseMapboxFeature(featureMap);
            
            if (address != null && address.isNotEmpty) {
              // Prefer addresses with street numbers or multiple parts
              final parts = address.split(',');
              if (parts.length >= 2 || RegExp(r'^\d+').hasMatch(address)) {
                return address;
              }
            }
          }
          
          // Use first result if no detailed match
          final address = _parseMapboxFeature(features.first as Map<String, dynamic>);
          if (address != null && address.isNotEmpty) {
            return address;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse Mapbox feature into readable address
  String? _parseMapboxFeature(Map<String, dynamic> feature) {
    final placeName = feature['place_name'] as String? ?? '';
    final text = feature['text'] as String? ?? '';
    final address = feature['address'] as String? ?? '';
    final placeType = (feature['place_type'] as List?)?.cast<String>() ?? [];
    final context = (feature['context'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    String street = '';
    String suburb = '';
    String city = '';

    // Build street name with number
    if (placeType.contains('address')) {
      if (address.isNotEmpty && text.isNotEmpty) {
        street = '$address $text';
      } else if (text.isNotEmpty) {
        street = text;
      } else {
        final parts = placeName.split(',').map((s) => s.trim()).toList();
        if (parts.isNotEmpty) street = parts.first;
      }
    } else if (placeType.contains('poi')) {
      street = text;
    } else if (placeType.contains('neighborhood')) {
      suburb = text;
    }

    // Extract neighborhood and city from context
    for (final c in context) {
      final id = c['id'] as String? ?? '';
      final contextText = c['text'] as String? ?? '';

      if (id.startsWith('neighborhood') && suburb.isEmpty) {
        suburb = contextText;
      } else if (id.startsWith('locality') && suburb.isEmpty && !placeType.contains('locality')) {
        suburb = contextText;
      } else if (id.startsWith('place') && city.isEmpty) {
        city = contextText;
      }
    }

    // Build final address
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (city.isNotEmpty) parts.add(city);

    // Remove duplicates (case-insensitive)
    final seen = <String>{};
    final unique = parts.where((s) => seen.add(s.toLowerCase())).toList();

    return unique.isEmpty ? null : unique.join(', ');
  }

  Future<void> _saveHomeLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final address = _addressController.text.trim();
      if (address.isEmpty) {
        setState(() {
          _error = 'Please enter your home address';
          _isLoading = false;
        });
        return;
      }

      // Save coordinates to local cache AND sync to backend (STAGING)
      // ALWAYS use detected coordinates if available, even if user edited the address
      if (_detectedPosition != null) {
        // Use detected GPS coordinates (most accurate)
        await _homeLocationService.setHomeLocation(
          latitude: _detectedPosition!.latitude,
          longitude: _detectedPosition!.longitude,
          address: address,
        );
      } else {
        // Geocode the manual address and sync coordinates to backend
        // This will throw an error if geocoding fails
        await _homeLocationService.setHomeLocationFromAddress(address);
      }

      // Also send address text to backend
      await _apiService.updateParentProfile(
        address: address,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onLocationSet();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home location successfully updated'),
            backgroundColor: Color(0xFF34C759),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surface,
      child: Container(
        constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 85.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 2.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Home icon with background
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home_rounded,
                      color: colorScheme.primary,
                      size: 8.w,
                    ),
                  ),
                  SizedBox(height: 1.5.h),
                  // Title
                  Text(
                    'Set your home',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 0.5.h),
                  // Subtitle
                  Text(
                    'For accurate drop-off & pick-up',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Scrollable content to prevent keyboard overflow
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.5.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                            // GPS accuracy badge
                            Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gps_fixed_rounded,
                                size: 4.w,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Best accuracy with GPS',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                              SizedBox(height: 2.h),

                        // Primary CTA: Use current location
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _detectCurrentLocation,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 5.w,
                                  height: 5.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.my_location_rounded, size: 5.w),
                          label: Text(
                            _isLoading ? 'Detecting location…' : 'Use current location',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.6.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                              ),

                        // Detected address display
                        if (_detectedAddress != null) ...[
                          SizedBox(height: 1.5.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(3.5.w),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: colorScheme.primary,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Detected address',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.sp,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 0.8.h),
                                Text(
                                  _detectedAddress!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                              ],

                        SizedBox(height: 1.5.h),

                        // Secondary option: Type address
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isManualEntry = !_isManualEntry;
                                  });
                                },
                          icon: Icon(
                            _isManualEntry ? Icons.close_rounded : Icons.edit_location_alt_rounded,
                            size: 4.5.w,
                          ),
                          label: Text(
                            _isManualEntry ? 'Cancel typing' : 'Type address instead',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.5),
                            ),
                          ),
                              ),

                        // Manual address input
                        if (_isManualEntry) ...[
                          SizedBox(height: 1.5.h),
                          TextField(
                            controller: _addressController,
                            maxLines: 2,
                            minLines: 1,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Your home address',
                              labelStyle: TextStyle(fontSize: 12.sp),
                              hintText: 'e.g., Riverside Square, Lower east',
                              hintStyle: TextStyle(fontSize: 12.sp, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                              prefixIcon: Icon(Icons.location_on_outlined, size: 5.w),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 3.w,
                                vertical: 1.5.h,
                              ),
                            ),
                          ),
                              ],

                        // Error display
                        if (_error != null) ...[
                          SizedBox(height: 1.5.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: colorScheme.error,
                                  size: 5.w,
                                ),
                                SizedBox(width: 2.5.w),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                      fontSize: 11.5.sp,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                              ],

                        SizedBox(height: 2.h),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 1.4.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Not now',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: _isLoading ||
                                        (_addressController.text.trim().isEmpty &&
                                            _detectedAddress == null)
                                    ? null
                                    : _saveHomeLocation,
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 1.4.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, size: 4.5.w),
                                    SizedBox(width: 1.5.w),
                                    Text(
                                      'Save as home',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
