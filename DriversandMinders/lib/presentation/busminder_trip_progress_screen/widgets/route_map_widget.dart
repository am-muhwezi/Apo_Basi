import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

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
    final currentLat = widget.locationData['latitude'] as double? ?? 40.7128;
    final currentLng = widget.locationData['longitude'] as double? ?? -74.0060;

    _markers.add(
      Marker(
        markerId: const MarkerId('bus_location'),
        position: LatLng(currentLat, currentLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Bus Location',
          snippet: 'Current position',
        ),
      ),
    );

    // Stop markers
    for (int i = 0; i < widget.stops.length; i++) {
      final stop = widget.stops[i];
      final lat = stop['latitude'] as double? ?? 40.7128;
      final lng = stop['longitude'] as double? ?? -74.0060;
      final name = stop['name'] as String? ?? 'Stop ${i + 1}';
      final isCompleted = stop['completed'] as bool? ?? false;
      final studentCount = stop['studentCount'] as int? ?? 0;

      _markers.add(
        Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isCompleted ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: name,
            snippet: '$studentCount students',
          ),
        ),
      );
    }
  }

  void _createRoute() {
    if (widget.stops.isEmpty) return;

    List<LatLng> routePoints = [];

    // Add current location
    final currentLat = widget.locationData['latitude'] as double? ?? 40.7128;
    final currentLng = widget.locationData['longitude'] as double? ?? -74.0060;
    routePoints.add(LatLng(currentLat, currentLng));

    // Add all stops
    for (final stop in widget.stops) {
      final lat = stop['latitude'] as double? ?? 40.7128;
      final lng = stop['longitude'] as double? ?? -74.0060;
      routePoints.add(LatLng(lat, lng));
    }

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: AppTheme.primaryBusminder,
        width: 4,
        patterns: [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLat = widget.locationData['latitude'] as double? ?? 40.7128;
    final currentLng = widget.locationData['longitude'] as double? ?? -74.0060;

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
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(currentLat, currentLng),
                zoom: 13.0,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: true,
              indoorViewEnabled: false,
              mapType: MapType.normal,
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
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(LatLng(currentLat, currentLng)),
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

