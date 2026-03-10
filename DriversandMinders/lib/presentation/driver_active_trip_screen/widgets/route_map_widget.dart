import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../config/api_config.dart';
import 'bus_marker_3d.dart';

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
  final MapController _mapController = MapController();
  // This widget no longer owns a live GPS stream. Driver location is
  // provided by higher-level screens via tripData or backend polling.
  // _currentPosition is kept only for potential future use but is not
  // updated via Geolocator here.
  Position? _currentPosition;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isLoading = true;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Request location permission
      await _requestLocationPermission();

      // NOTE: This widget no longer starts its own GPS tracking. The
      // driver/bus position should be supplied from the parent via
      // tripData or other props.

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

  // Previously this widget owned its own Geolocator stream; that logic has
  // been removed to avoid multiple competing GPS clients. Camera movement is
  // now controlled by the parent screen's map.

  void _setupMarkersAndRoute() {
    // Sort stops by `order` field so the polyline always follows the correct sequence
    final stops = ((widget.tripData["stops"] as List? ?? [])
            .cast<Map<String, dynamic>>()
          ..sort((a, b) =>
              (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0)))
        .toList();
    final List<Marker> markers = [];
    final List<Polyline> polylines = [];

    // Driver's current location with 3D bus marker that rotates based on heading
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 60,
          height: 60,
          child: BusMarker3D(
            size: 60,
            heading: _currentPosition!.heading, // Rotate based on GPS heading
            isMoving: _currentPosition!.speed > 0.5, // Moving if speed > 0.5 m/s (~1.8 km/h)
          ),
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
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: Icon(
            Icons.location_on,
            color: isCompleted ? Colors.green : Colors.red,
            size: 40,
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
          points: routePoints,
          color: AppTheme.primaryDriver,
          strokeWidth: 4,
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
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
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : LatLng(0.3476, 32.5825), // Default to Kampala
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: ApiConfig.getMapboxTileUrl(),
          userAgentPackageName: 'com.apobasi.driversandminders',
          maxZoom: 19,
        ),
        PolylineLayer(
          polylines: _polylines,
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    );
  }
}

