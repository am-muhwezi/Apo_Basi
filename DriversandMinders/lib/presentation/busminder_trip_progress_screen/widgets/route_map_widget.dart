import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../config/api_config.dart';

class RouteMapWidget extends StatefulWidget {
  final Map<String, dynamic> locationData;
  final List<Map<String, dynamic>> stops;

  const RouteMapWidget({
    super.key,
    required this.locationData,
    required this.stops,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    _createMarkers();
    _createRoute();
  }

  void _createMarkers() {
    _markers.clear();

    // Current bus location
    final currentLat = widget.locationData['latitude'] as double? ?? 0.3476;
    final currentLng = widget.locationData['longitude'] as double? ?? 32.5825;

    _markers.add(
      Marker(
        point: LatLng(currentLat, currentLng),
        width: 40,
        height: 40,
        child: Icon(
          Icons.directions_bus,
          color: Colors.blue,
          size: 40,
        ),
      ),
    );

    // Stop markers
    for (int i = 0; i < widget.stops.length; i++) {
      final stop = widget.stops[i];
      final lat = stop['latitude'] as double? ?? 0.3476;
      final lng = stop['longitude'] as double? ?? 32.5825;
      final name = stop['name'] as String? ?? 'Stop ${i + 1}';
      final isCompleted = stop['completed'] as bool? ?? false;
      final studentCount = stop['studentCount'] as int? ?? 0;

      _markers.add(
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
  }

  void _createRoute() {
    if (widget.stops.isEmpty) return;

    List<LatLng> routePoints = [];

    // Add current location
    final currentLat = widget.locationData['latitude'] as double? ?? 0.3476;
    final currentLng = widget.locationData['longitude'] as double? ?? 32.5825;
    routePoints.add(LatLng(currentLat, currentLng));

    // Add all stops
    for (final stop in widget.stops) {
      final lat = stop['latitude'] as double? ?? 0.3476;
      final lng = stop['longitude'] as double? ?? 32.5825;
      routePoints.add(LatLng(lat, lng));
    }

    _polylines.add(
      Polyline(
        points: routePoints,
        color: AppTheme.primaryBusminder,
        strokeWidth: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLat = widget.locationData['latitude'] as double? ?? 0.3476;
    final currentLng = widget.locationData['longitude'] as double? ?? 32.5825;

    return Container(
      width: double.infinity,
      height: 25.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(currentLat, currentLng),
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
            ),
            Positioned(
              top: 2.h,
              left: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'directions_bus',
                      color: AppTheme.primaryBusminder,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Live Route',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBusminder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 2.h,
              right: 4.w,
              child: FloatingActionButton.small(
                onPressed: () {
                  _mapController.move(
                    LatLng(currentLat, currentLng),
                    _mapController.camera.zoom,
                  );
                },
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: AppTheme.primaryBusminder,
                child: CustomIconWidget(
                  iconName: 'my_location',
                  color: AppTheme.primaryBusminder,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

