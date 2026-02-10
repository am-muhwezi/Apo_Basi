import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sizer/sizer.dart';

import '../../../services/home_location_service.dart';
import '../../../services/api_service.dart';

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
          _error = 'Location permission denied. Please enter address manually.';
          _isManualEntry = true;
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;

        // Build a more user-friendly address with actual place names
        final addressParts = <String>[];

        // Helper function to check if string is a Plus Code (e.g., PQJR+H4F)
        bool isPlusCode(String text) {
          return RegExp(r'^[A-Z0-9]{4}\+[A-Z0-9]{2,3}$').hasMatch(text.trim());
        }

        // Helper function to check if string is meaningful
        bool isMeaningfulName(String? text) {
          if (text == null || text.isEmpty) return false;
          if (text.contains(RegExp(r'^\d+$'))) return false;
          if (isPlusCode(text)) return false;
          if (text.length < 3) return false;
          return true;
        }

        // Prioritize street name
        if (isMeaningfulName(placemark.street)) {
          addressParts.add(placemark.street!);
        }

        // Add subLocality for neighborhood (e.g., "Westlands", "Kilimani")
        if (isMeaningfulName(placemark.subLocality) &&
            !addressParts.contains(placemark.subLocality)) {
          addressParts.add(placemark.subLocality!);
        }

        // Add thoroughfare (main road) if available
        if (isMeaningfulName(placemark.thoroughfare) &&
            !addressParts.contains(placemark.thoroughfare) &&
            placemark.thoroughfare != placemark.street) {
          addressParts.add(placemark.thoroughfare!);
        }

        // Add locality (city - e.g., "Nairobi")
        if (isMeaningfulName(placemark.locality) &&
            !addressParts.contains(placemark.locality)) {
          addressParts.add(placemark.locality!);
        }

        // Only add name if meaningful and not already included
        if (isMeaningfulName(placemark.name) &&
            !addressParts.contains(placemark.name)) {
          addressParts.add(placemark.name!);
        }

        // Remove duplicates and Plus Codes
        final uniqueParts = <String>[];
        for (final part in addressParts) {
          if (isPlusCode(part)) continue;

          bool isDuplicate = uniqueParts.any((existing) =>
              existing.toLowerCase() == part.toLowerCase() ||
              existing.toLowerCase().contains(part.toLowerCase()) ||
              part.toLowerCase().contains(existing.toLowerCase()));

          if (!isDuplicate) {
            uniqueParts.add(part);
          }
        }

        // Build final address
        String address;
        if (uniqueParts.isNotEmpty) {
          address = uniqueParts.join(', ');
        } else {
          // Fallback to administrative areas
          final fallbackParts = <String>[];
          if (isMeaningfulName(placemark.administrativeArea)) {
            fallbackParts.add(placemark.administrativeArea!);
          }
          if (isMeaningfulName(placemark.locality)) {
            fallbackParts.add(placemark.locality!);
          }

          address = fallbackParts.isNotEmpty
              ? fallbackParts.join(', ')
              : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }

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
          _error = 'Could not detect location. Please enter manually.';
          _isManualEntry = true;
          _isLoading = false;
        });
      }
    }
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

      // Save to local cache
      // ALWAYS use detected coordinates if available, even if user edited the address
      if (_detectedPosition != null) {
        // Use detected GPS coordinates (most accurate)
        await _homeLocationService.setHomeLocation(
          latitude: _detectedPosition!.latitude,
          longitude: _detectedPosition!.longitude,
          address: address,
        );
      } else {
        // Geocode the manual address only if we don't have GPS coordinates
        await _homeLocationService.setHomeLocationFromAddress(address);
      }

      // Send to backend
      await _apiService.updateParentProfile(
        address: address,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onLocationSet();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home location saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save location: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_rounded,
              color: theme.colorScheme.primary,
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your home',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  'For accurate drop-off & pick-up',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // GPS accuracy badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.6.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 3.5.w,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 1.5.w),
                  Text(
                    'Best accuracy with GPS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.5.h),

            // Primary action: detect current location
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _detectCurrentLocation,
                icon: _isLoading
                    ? SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.my_location, size: 4.5.w),
                label: Text(
                  _isLoading ? 'Detecting…' : 'Use current location',
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_detectedAddress != null) ...[
              SizedBox(height: 1.2.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 4.5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detected address',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 0.3.h),
                          Text(
                            _detectedAddress!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.sp,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 1.2.h),

            // Manual entry (secondary path)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isManualEntry = true;
                });
              },
              icon: Icon(Icons.edit_location_alt_outlined, size: 4.w),
              label: Text(
                'Type address instead',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            if (_isManualEntry) ...[
              SizedBox(height: 0.8.h),
              TextField(
                controller: _addressController,
                maxLines: 1,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  labelText: 'Home address',
                  labelStyle: TextStyle(fontSize: 12.sp),
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

            if (_error != null) ...[
              SizedBox(height: 1.2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(4.w, 0.5.h, 4.w, 1.5.h),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(
            'Not now',
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        FilledButton(
          onPressed: _isLoading ||
                  (_addressController.text.trim().isEmpty &&
                      _detectedAddress == null)
              ? null
              : _saveHomeLocation,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Save as home',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
