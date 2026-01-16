import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../config/mapbox_config.dart';
import '../../config/location_config.dart';
import './widgets/home_marker_widget.dart';
import '../../widgets/location/bus_marker_3d.dart';
import '../../widgets/location/animated_bus_marker.dart';
import '../../models/bus_location_model.dart';
import '../../services/bus_websocket_service.dart';
import '../../services/mapbox_route_service.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({Key? key}) : super(key: key);

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  Map<String, dynamic>? _childData;
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  // Real-time bus tracking
  final BusWebSocketService _webSocketService = BusWebSocketService();
  BusLocation? _busLocation;
  LatLng? _snappedBusLocation; // Road-snapped bus location
  LocationConnectionState _connectionState =
      LocationConnectionState.disconnected;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectionSubscription;

  // ETA and Route Information
  int? _etaMinutes;
  List<LatLng>? _routePoints;
  String? _distance;
  bool _isCalculatingETA = false;

  @override
  void initState() {
    super.initState();
    _initializeSocketConnection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _childData = args;
    }
    _getCurrentLocation();
    _subscribeToBus();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    // Don't disconnect WebSocket - it's a singleton shared across the app
    // The WebSocket should remain connected for real-time notifications
    super.dispose();
  }

  /// Initialize WebSocket connection for real-time bus tracking
  Future<void> _initializeSocketConnection() async {
    try {
      // Connect to WebSocket service (initialize)
      await _webSocketService.connect();

      // Listen to connection state FIRST
      _connectionSubscription =
          _webSocketService.connectionStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _connectionState = state;
          });

          // Subscribe to bus when connected
          if (state == LocationConnectionState.connected) {
            _subscribeToBus();
          }
        }
      });

      // Listen to location updates
      _locationSubscription =
          _webSocketService.locationUpdateStream.listen((location) {
        if (mounted) {
          setState(() {
            _busLocation = location;
          });

          // Snap to road and calculate ETA when bus location updates
          _updateBusLocationWithSnapping(location);
        }
      }, onError: (error) {
        if (LocationConfig.enableSocketLogging) {}
      });

      // If already connected, subscribe immediately
      if (_webSocketService.isConnected) {
        _subscribeToBus();
      } else {
        // Subscribe anyway - this will trigger the actual WebSocket connection
        _subscribeToBus();
      }
    } catch (e) {
      // Failed to initialize WebSocket
    }
  }

  /// Subscribe to bus location updates
  void _subscribeToBus() {
    if (_childData == null) {
      return;
    }

    final busValue = _childData!['busId'];
    if (busValue == null) {
      return;
    }

    final busId =
        busValue is int ? busValue : int.tryParse(busValue.toString());
    if (busId == null) {
      return;
    }

    _webSocketService.subscribeToBus(busId);
  }

  /// Update bus location with road snapping and ETA calculation
  Future<void> _updateBusLocationWithSnapping(BusLocation location) async {
    if (_currentPosition == null) return;

    setState(() {
      _isCalculatingETA = true;
    });

    try {
      final busCoord = LatLng(location.latitude, location.longitude);
      final homeCoord =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

      // Snap bus location to nearest road
      final snappedCoord = await MapboxRouteService.snapSinglePointToRoad(
        coordinate: busCoord,
        radius: 25, // Search within 25 meters
      );

      // Get comprehensive trip information (route, ETA, distance)
      final tripInfo = await MapboxRouteService.getTripInformation(
        busLocation: snappedCoord ?? busCoord,
        homeLocation: homeCoord,
        profile: 'driving-traffic', // Use real-time traffic data
      );

      if (mounted && tripInfo != null) {
        setState(() {
          _snappedBusLocation = snappedCoord;
          _etaMinutes = tripInfo['eta'];
          _distance = tripInfo['distance'];
          _routePoints = tripInfo['route'];
          _isCalculatingETA = false;
        });
      } else {
        setState(() {
          _isCalculatingETA = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCalculatingETA = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Center map on current location or bus if available
      if (_busLocation != null) {
        _mapController.move(
          LatLng(_busLocation!.latitude, _busLocation!.longitude),
          14.0,
        );
      } else {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_childData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('No child data available'),
        ),
      );
    }

    final String name = _childData!['name'] ?? 'Child Name';
    final String grade = _childData!['grade'] ?? 'N/A';
    final bool hasAssignedBus = _childData!['busId'] != null;
    final bool isTrackable = hasAssignedBus && _busLocation != null;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Mapbox Map via flutter_map
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : _currentPosition != null
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        initialZoom: 14.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        // Mapbox Tile Layer (falls back to OSM if not configured)
                        TileLayer(
                          urlTemplate: MapboxConfig.getTileUrl(),
                          userAgentPackageName: 'com.apobasi.parentsapp',
                          maxZoom: 19,
                        ),
                        // Route Polyline (from bus to home)
                        // Only show when we are actively tracking the bus.
                        if (hasAssignedBus &&
                            _routePoints != null &&
                            _routePoints!.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints!,
                                strokeWidth: 4.0,
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withOpacity(0.7),
                                borderColor: Colors.white,
                                borderStrokeWidth: 2.0,
                              ),
                            ],
                          ),
                        // Marker Layer
                        MarkerLayer(
                          markers: [
                            // Home marker
                            if (_currentPosition != null)
                              Marker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                width: 80,
                                height: 80,
                                child: const HomeMarkerWidget(),
                              ),
                            // Bus marker (3D Animated) - Using SNAPPED location for accurate road position
                            // Only show when we are actively tracking the bus.
                            if (isTrackable && _busLocation != null)
                              Marker(
                                point: _snappedBusLocation ??
                                    LatLng(
                                      _busLocation!.latitude,
                                      _busLocation!.longitude,
                                    ),
                                width: 100,
                                height: 100,
                                child: AnimatedBusMarker(
                                  position: _snappedBusLocation ??
                                      LatLng(
                                        _busLocation!.latitude,
                                        _busLocation!.longitude,
                                      ),
                                  size: 50,
                                  heading: _busLocation!.heading ?? 0,
                                  isMoving: (_busLocation!.speed ?? 0) > 0.5,
                                  vehicleNumber: _childData?['busNumber'],
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: AppTheme.lightTheme.colorScheme.error,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Unable to get location',
                            style: AppTheme.lightTheme.textTheme.titleLarge,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Please enable location permissions',
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

          // Top compact info widget
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      // Recenter button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.my_location,
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                          onPressed: () {
                            if (_busLocation != null) {
                              // Center on bus location
                              _mapController.move(
                                LatLng(_busLocation!.latitude,
                                    _busLocation!.longitude),
                                15.0,
                              );
                            } else if (_currentPosition != null) {
                              // Center on user location
                              _mapController.move(
                                LatLng(_currentPosition!.latitude,
                                    _currentPosition!.longitude),
                                14.0,
                              );
                            }
                          },
                          tooltip: 'Recenter map',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Small floating child info card
                  Center(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              grade,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info card and action buttons
          Positioned(
            bottom: 3.h,
            left: 4.w,
            right: 4.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact info card with ETA, distance, and call buttons
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top row: Bus info + ETA + Distance
                      Row(
                        children: [
                          // Bus icon and number
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.directions_bus,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 5.w,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          // Bus number
                          Text(
                            _childData?['busNumber'] ?? 'Unknown',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          // ETA and Distance
                          if (_etaMinutes != null || _distance != null)
                            Row(
                              children: [
                                if (_etaMinutes != null) ...[
                                  Icon(
                                    Icons.access_time,
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    size: 4.w,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    '$_etaMinutes min',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                                if (_etaMinutes != null && _distance != null)
                                  Container(
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 2.w),
                                    width: 1,
                                    height: 3.h,
                                    color: Colors.grey.shade300,
                                  ),
                                if (_distance != null) ...[
                                  Icon(
                                    Icons.straighten,
                                    color: Colors.grey.shade600,
                                    size: 4.w,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    '$_distance km',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      // Action buttons row
                      Row(
                        children: [
                          // Call School button
                          Expanded(
                            child: InkWell(
                              onTap: () => _callSchool(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme
                                        .lightTheme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'School',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          // Call Bus Assistant button
                          Expanded(
                            child: InkWell(
                              onTap: () => _callBusAssistant(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      color: Colors.white,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Assistant',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _callBusAssistant(BuildContext context) {
    // Calls bus assistant/driver
    final String assistantPhone = _childData?['assistantPhone'] ?? '';

    if (assistantPhone.isNotEmpty) {
      _makePhoneCall(assistantPhone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calling bus assistant...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _callSchool(BuildContext context) {
    // Calls school
    final String schoolPhone = _childData?['schoolPhone'] ?? '';

    if (schoolPhone.isNotEmpty) {
      _makePhoneCall(schoolPhone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calling school...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
