import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../config/api_config.dart';

/// Compact map widget showing driver's current location with bus icon
/// Displayed on the Driver Start Shift screen
class DriverLocationMapWidget extends StatefulWidget {
  final String busNumber;

  const DriverLocationMapWidget({
    super.key,
    required this.busNumber,
  });

  @override
  State<DriverLocationMapWidget> createState() => _DriverLocationMapWidgetState();
}

class _DriverLocationMapWidgetState extends State<DriverLocationMapWidget> {
  MapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Request location permission
      await _requestLocationPermission();

      // Get current location
      if (_hasLocationPermission) {
        await _getCurrentLocation();
        _startLocationUpdates();
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

  Future<void> _requestLocationPermission() async {
    if (kIsWeb) {
      _hasLocationPermission = true;
      return;
    }

    final status = await Permission.location.request();
    _hasLocationPermission = status.isGranted;
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!_hasLocationPermission) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Move map to current location
      _mapController?.move(
        LatLng(position.latitude, position.longitude),
        16.0,
      );
    } catch (e) {
    }
  }

  /// Start real-time location updates
  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _updateCamera(position);
    });
  }

  /// Update camera to follow bus
  void _updateCamera(Position position) {
    _mapController?.move(
      LatLng(position.latitude, position.longitude),
      16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 30.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map or loading state
            _isLoading
                ? _buildLoadingState(context)
                : _hasLocationPermission
                    ? _buildMapView()
                    : _buildNoPermissionState(context),

            // GPS status indicator
            Positioned(
              top: 2.h,
              left: 3.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _hasLocationPermission && _currentPosition != null
                      ? AppTheme.successAction.withValues(alpha: 0.9)
                      : AppTheme.warningState.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName:
                          _hasLocationPermission && _currentPosition != null
                              ? 'gps_fixed'
                              : 'gps_off',
                      color: AppTheme.textOnPrimary,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _hasLocationPermission && _currentPosition != null
                          ? 'GPS Active'
                          : 'GPS Off',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textOnPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bus info overlay
            if (_currentPosition != null)
              Positioned(
                bottom: 2.h,
                left: 3.w,
                right: 3.w,
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowLight,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: 'directions_bus',
                        label: 'Bus',
                        value: widget.busNumber,
                      ),
                      _buildInfoItem(
                        icon: 'speed',
                        label: 'Speed',
                        value: '${_currentPosition!.speed.toStringAsFixed(1)} m/s',
                      ),
                      _buildInfoItem(
                        icon: 'my_location',
                        label: 'Accuracy',
                        value: '±${_currentPosition!.accuracy.toInt()}m',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: icon,
          color: AppTheme.primaryDriver,
          size: 20,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 9.sp,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppTheme.backgroundSecondary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryDriver,
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading Map...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPermissionState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppTheme.backgroundSecondary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'location_off',
              color: AppTheme.criticalAlert,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'Location Permission Required',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please enable location services',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : LatLng(0.3476, 32.5825), // Default: Kampala, Uganda
        initialZoom: 16.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: ApiConfig.getMapboxTileUrl(),
          userAgentPackageName: 'com.apobasi.driversandminders',
          maxZoom: 19,
        ),
        if (_currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDriver,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bus ${widget.busNumber}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.directions_bus,
                      color: AppTheme.primaryDriver,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
