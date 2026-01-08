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
import '../../models/bus_location_model.dart';
import '../../services/socket_service.dart';
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
  final SocketService _socketService = SocketService();
  BusLocation? _busLocation;
  LatLng? _snappedBusLocation; // Road-snapped bus location
  LocationConnectionState _connectionState = LocationConnectionState.disconnected;
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
      // Don't subscribe immediately - wait for socket connection in initState
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    // Don't disconnect socket - it's a singleton shared across the app
    // The socket should remain connected for real-time notifications
    super.dispose();
  }

  /// Initialize Socket.IO connection for real-time bus tracking
  Future<void> _initializeSocketConnection() async {
    try {
      // Connect to Socket.IO
      await _socketService.connect();

      // Listen to connection state FIRST
      _connectionSubscription = _socketService.connectionStateStream.listen((state) {
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
      _locationSubscription = _socketService.locationUpdateStream.listen((location) {
        if (mounted) {
          setState(() {
            _busLocation = location;
          });

          // Snap to road and calculate ETA when bus location updates
          _updateBusLocationWithSnapping(location);
        }
      }, onError: (error) {
        if (LocationConfig.enableSocketLogging) {
          print('CHILD DETAIL: Error in location stream: $error');
        }
      });

      // If already connected, subscribe immediately
      if (_socketService.isConnected) {
        _subscribeToBus();
      }
    } catch (e) {
      print('ERROR: Failed to initialize socket connection: $e');
    }
  }

  /// Subscribe to bus location updates
  void _subscribeToBus() {
    if (_childData != null && _childData!['busId'] != null) {
      final busId = _childData!['busId'] as int;
      _socketService.subscribeToBus(busId);
    }
  }

  /// Update bus location with road snapping and ETA calculation
  Future<void> _updateBusLocationWithSnapping(BusLocation location) async {
    if (_currentPosition == null) return;

    setState(() {
      _isCalculatingETA = true;
    });

    try {
      final busCoord = LatLng(location.latitude, location.longitude);
      final homeCoord = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

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
      print('Error updating bus location with snapping: $e');
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
                        if (_routePoints != null && _routePoints!.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints!,
                                strokeWidth: 4.0,
                                color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.7),
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
                            // Bus marker (3D) - Using SNAPPED location for accurate road position
                            if (_busLocation != null)
                              Marker(
                                point: _snappedBusLocation ?? LatLng(
                                  _busLocation!.latitude,
                                  _busLocation!.longitude,
                                ),
                                width: 100,
                                height: 100,
                                child: BusMarker3D(
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
                    ],
                  ),
                  SizedBox(height: 2.h),
                  // Small floating child info card
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
                // ETA Display Card
                if (_etaMinutes != null && _busLocation != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 1.5.h),
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.lightTheme.colorScheme.primary,
                          AppTheme.lightTheme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 6.w,
                        ),
                        SizedBox(width: 3.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Arriving in',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 9.sp,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$_etaMinutes',
                                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28.sp,
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  _etaMinutes == 1 ? 'minute' : 'minutes',
                                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_distance != null) ...[
                          SizedBox(width: 4.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_distance km',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (_isCalculatingETA)
                          Container(
                            margin: EdgeInsets.only(left: 3.w),
                            width: 20,
                            height: 20,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Bus info card
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_bus,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 6.w,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'School Bus',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  fontSize: 9.sp,
                                ),
                              ),
                              Text(
                                _childData?['busNumber'] ?? 'YD',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),
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
                                    color: AppTheme.lightTheme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      color: AppTheme.lightTheme.colorScheme.primary,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'School',
                                      style: AppTheme.lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.lightTheme.colorScheme.primary,
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
                                  color: AppTheme.lightTheme.colorScheme.primary,
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
                                      style: AppTheme.lightTheme.textTheme.bodySmall
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
