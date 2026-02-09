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
        final addressParts = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((part) => part != null && part.isNotEmpty);

        final address = addressParts.join(', ');

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
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.home,
            color: Theme.of(context).colorScheme.primary,
            size: 6.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Set Home Location',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We need your home address to show accurate tracking and ETAs for your children.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            if (!_isManualEntry && _detectedAddress != null) ...[
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Detected Location',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
              ],
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Home Address',
                  hintText: 'Enter your full home address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.edit_location),
                ),
                onChanged: (value) {
                  setState(() {
                    _isManualEntry = true;
                  });
                },
              ),
              SizedBox(height: 1.h),
              if (!_isLoading && _detectedAddress == null)
                OutlinedButton.icon(
                  onPressed: _detectCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Detect My Location'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                )
              else if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Detecting location...'),
                      ],
                    ),
                  ),
                ),
              if (_error != null) ...[
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Theme.of(context).colorScheme.error,
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
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Skip for Now'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveHomeLocation,
          child: _isLoading
              ? SizedBox(
                  width: 4.w,
                  height: 4.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Location'),
        ),
      ],
    );
  }
}
