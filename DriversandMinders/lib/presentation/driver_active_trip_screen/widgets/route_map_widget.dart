import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Interactive route map widget with real-time location
class RouteMapWidget extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final Function() onFullScreenTap;

  const RouteMapWidget({
    super.key,
    required this.tripData,
    required this.onFullScreenTap,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
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
        _startLocationUpdates(); // Start real-time tracking
      }

      // Setup markers and route
      _setupMarkersAndRoute();

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
    } catch (e) {
      // Handle location error silently
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
      _setupMarkersAndRoute(); // Update markers with new position
      _updateCamera(position);
    });
  }

  /// Update camera to follow bus
  void _updateCamera(Position position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  void _setupMarkersAndRoute() {
    final stops = (widget.tripData["stops"] as List? ?? []);
    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    // Add current bus location marker (YELLOW)
    if (_currentPosition != null) {
      final busNumber = widget.tripData["busNumber"]?.toString() ?? 'Bus';
      markers.add(
        Marker(
          markerId: MarkerId('bus_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow, // Yellow marker for bus
          ),
          infoWindow: InfoWindow(
            title: 'Bus $busNumber',
            snippet: 'Your current location',
          ),
          rotation: _currentPosition!.heading,
        ),
      );
    }

    // Add stop markers
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i] as Map<String, dynamic>;
      final lat = (stop["latitude"] as num?)?.toDouble() ?? 40.7128;
      final lng = (stop["longitude"] as num?)?.toDouble() ?? -74.0060;
      final stopName = stop["name"] as String? ?? "Stop ${i + 1}";
      final isCompleted = stop["isCompleted"] as bool? ?? false;

      markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isCompleted ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: stopName,
            snippet: isCompleted ? 'Completed' : 'Pending',
          ),
        ),
      );
    }

    // Create route polyline
    if (stops.isNotEmpty) {
      final List<LatLng> routePoints = [];

      // Add current location if available
      if (_currentPosition != null) {
        routePoints.add(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
      }

      // Add all stops
      for (final stop in stops) {
        final lat = (stop["latitude"] as num?)?.toDouble() ?? 40.7128;
        final lng = (stop["longitude"] as num?)?.toDouble() ?? -74.0060;
        routePoints.add(LatLng(lat, lng));
      }

      polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: routePoints,
          color: AppTheme.primaryDriver,
          width: 4,
          patterns: [],
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move camera to current location or first stop
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    } else {
      final stops = (widget.tripData["stops"] as List? ?? []);
      if (stops.isNotEmpty) {
        final firstStop = stops[0] as Map<String, dynamic>;
        final lat = (firstStop["latitude"] as num?)?.toDouble() ?? 40.7128;
        final lng = (firstStop["longitude"] as num?)?.toDouble() ?? -74.0060;

        controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 13.0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 35.h,
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
            _isLoading ? _buildLoadingState(context) : _buildMapView(),

            // Full screen button
            Positioned(
              top: 2.h,
              right: 3.w,
              child: GestureDetector(
                onTap: widget.onFullScreenTap,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowLight,
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: CustomIconWidget(
                    iconName: 'fullscreen',
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),

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

            // Bus info overlay at bottom
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
                        value: widget.tripData["busNumber"]?.toString() ?? 'N/A',
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

  Widget _buildMapView() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : LatLng(40.7128, -74.0060), // Default to NYC
        zoom: 13.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: _hasLocationPermission,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
      buildingsEnabled: true,
      onTap: (LatLng position) {
        // Handle map tap if needed
      },
    );
  }
}

