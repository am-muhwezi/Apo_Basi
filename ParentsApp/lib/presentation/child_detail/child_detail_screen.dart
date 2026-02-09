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
import '../../config/cached_tile_provider.dart';
import './widgets/home_marker_widget.dart';
import '../../widgets/location/bus_marker_3d.dart';
import '../../widgets/location/animated_bus_marker.dart';
import '../../models/bus_location_model.dart';
import '../../services/bus_websocket_service.dart';
import '../../services/mapbox_route_service.dart';
import '../../services/home_location_service.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({Key? key}) : super(key: key);

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  Map<String, dynamic>? _childData;
  final MapController _mapController = MapController();
  LatLng? _homeLocation; // Child's home location (static, not GPS)
  bool _isLoadingLocation = true;
  final HomeLocationService _homeLocationService = HomeLocationService();

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
    // Defer WebSocket connection to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketConnection();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _childData = args;
    }
    _loadHomeLocation();
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
    if (_homeLocation == null) return;

    setState(() {
      _isCalculatingETA = true;
    });

    try {
      final busCoord = LatLng(location.latitude, location.longitude);
      final homeCoord =
          LatLng(_homeLocation!.latitude, _homeLocation!.longitude);

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

  /// Load child's home location (not parent's GPS location)
  /// Parents don't share their location - this is the child's static home address
  /// Uses parent's saved home location from HomeLocationService
  Future<void> _loadHomeLocation() async {
    try {
      // FIRST: Try to get parent's cached home coordinates (set in profile)
      LatLng? homeCoords = await _homeLocationService.getHomeCoordinates();

      // SECOND: Try to get the saved address and geocode if no coords
      if (homeCoords == null) {
        final String? savedAddress = await _homeLocationService.getHomeAddress();
        if (savedAddress != null && savedAddress.isNotEmpty) {
          // Try to geocode the saved address - wait for completion
          bool success = await _homeLocationService.setHomeLocationFromAddress(savedAddress);
          if (success) {
            homeCoords = await _homeLocationService.getHomeCoordinates();
          }
        }
      }

      // THIRD: Try child's address from backend as last resort
      if (homeCoords == null && _childData != null) {
        final String? childAddress = _childData!['homeAddress'] ?? _childData!['address'];
        if (childAddress != null && childAddress.isNotEmpty && childAddress != 'Not set') {
          bool success = await _homeLocationService.setHomeLocationFromAddress(childAddress);
          if (success) {
            homeCoords = await _homeLocationService.getHomeCoordinates();
          }
        }
      }

      // Final fallback: Nairobi city center (only if no coordinates found)
      homeCoords ??= const LatLng(-1.286389, 36.817223);

      if (!mounted) return;

      setState(() {
        _homeLocation = homeCoords;
        _isLoadingLocation = false;
      });

      // Center map after it's rendered - use postFrameCallback
      final finalHomeCoords = homeCoords; // Capture for closure
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || finalHomeCoords == null) return;
        try {
          // Center map on bus location if available, otherwise home
          if (_busLocation != null) {
            _mapController.move(
              LatLng(_busLocation!.latitude, _busLocation!.longitude),
              19.5,
            );
          } else {
            _mapController.move(finalHomeCoords, 19.0);
          }
        } catch (e) {
          // Map not yet ready, ignore
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _homeLocation = const LatLng(-1.286389, 36.817223);
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _getTripStatus() {
    final String childName = _childData?['name'] ?? 'Child';
    final String? status = _childData?['status']?.toString().toLowerCase();

    // Use child's actual location_status from backend
    if (status == 'on-bus' || status == 'on_bus' || status == 'picked-up' || status == 'picked_up') {
      // Child is on the bus
      if (_busLocation != null) {
        final isMoving = (_busLocation!.speed ?? 0) > 0.5;

        if (!isMoving) {
          return 'Bus Stopped';
        }

        // Check ETA
        if (_etaMinutes != null) {
          if (_etaMinutes! <= 5) {
            return 'Driver arrives soon';
          } else if (_etaMinutes! <= 15) {
            return 'Driver on the way';
          }
        }

        return 'Driver on the way';
      }
      return '$childName is on the bus';
    } else if (status == 'at-school' || status == 'at_school') {
      return '$childName is at school';
    } else if (status == 'dropped-off' || status == 'dropped_off' || status == 'home') {
      return '$childName is Home';
    } else {
      // Default fallback
      return '$childName is Home';
    }
  }

  String _getRouteDisplay() {
    // Try to get route name from various possible fields
    final routeName = _childData?['routeName'] ??
                      _childData?['route_name'] ??
                      _childData?['route'];

    // If route name exists and is not empty
    if (routeName != null && routeName.toString().trim().isNotEmpty) {
      return routeName.toString();
    }

    // Try to get route code as fallback
    final routeCode = _childData?['routeCode'] ?? _childData?['route_code'];
    if (routeCode != null && routeCode.toString().trim().isNotEmpty) {
      return routeCode.toString();
    }

    // Check if child has an assigned bus
    final hasBus = _childData?['busId'] != null &&
                   _childData?['busNumber'] != null &&
                   _childData!['busNumber'] != 'N/A';

    if (hasBus) {
      return 'As directed by school';
    } else {
      return 'Not yet assigned';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Mapbox Map via flutter_map
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : _homeLocation != null
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _homeLocation!.latitude,
                          _homeLocation!.longitude,
                        ),
                        initialZoom: 19.0,
                        minZoom: 5.0,
                        maxZoom: 22.0,
                      ),
                      children: [
                        // Mapbox Tile Layer - uses default caching
                        TileLayer(
                          urlTemplate: MapboxConfig.getTileUrl(),
                          userAgentPackageName: 'com.apobasi.parentsapp',
                          maxZoom: 19,
                          // Use default tile provider for faster loading
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
                                strokeWidth: 5.0,
                                color: const Color(0xFF5B7FFF),
                              ),
                            ],
                          ),
                        // Marker Layer
                        MarkerLayer(
                          markers: [
                            // Home marker
                            if (_homeLocation != null)
                              Marker(
                                point: LatLng(
                                  _homeLocation!.latitude,
                                  _homeLocation!.longitude,
                                ),
                                width: 48,
                                height: 48,
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
                            color: Theme.of(context).colorScheme.error,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Unable to get location',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Please enable location permissions',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

          // Clean top UI - only back button and recenter button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  // Recenter button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        if (_busLocation != null) {
                          // Center on bus location
                          _mapController.move(
                            LatLng(_busLocation!.latitude,
                                _busLocation!.longitude),
                            19.5,
                          );
                        } else if (_homeLocation != null) {
                          // Center on home location
                          _mapController.move(
                            LatLng(_homeLocation!.latitude,
                                _homeLocation!.longitude),
                            19.0,
                          );
                        }
                      },
                      tooltip: 'Recenter map',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Modern DraggableScrollableSheet
          DraggableScrollableSheet(
            initialChildSize: 0.18,
            minChildSize: 0.15,
            maxChildSize: 0.50,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(5.w, 1.5.h, 5.w, 2.h),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 1.5.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Trip Status Header with ETA Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTripStatus(),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (_etaMinutes != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '$_etaMinutes min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 1.5.h),

                    // Driver Photo Circle (clean, no badge)
                    Row(
                      children: [
                        // Driver photo circle - clean design
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15),
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        // Driver and Route Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Driver Name or Bus Assignment Status
                              Text(
                                _childData?['busId'] == null
                                    ? 'Not yet assigned to a bus'
                                    : (_childData?['driverName'] ?? 'Driver'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.sp,
                                      color: _childData?['busId'] == null
                                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Only show bus number and route if child has a bus assigned
                              if (_childData?['busId'] != null) ...[
                                SizedBox(height: 0.5.h),
                                // Bus Number Plate - theme-aware colors
                                if (_childData?['busNumber'] != null &&
                                    _childData!['busNumber'] != 'N/A')
                                  Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.5.w,
                                    vertical: 0.4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.directions_bus,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      SizedBox(width: 1.w),
                                      Text(
                                        _childData!['busNumber'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 11.sp,
                                              letterSpacing: 0.8,
                                            ),
                                      ),
                                    ],
                                  ),
                                  ),
                                SizedBox(height: 0.5.h),
                                // Route Information with fallback
                                Row(
                                children: [
                                  Icon(
                                    Icons.route,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  SizedBox(width: 1.5.w),
                                  Expanded(
                                    child: Text(
                                      _getRouteDisplay(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11.sp,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 1.5.h),

                    // Divider
                    Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.1),
                      thickness: 1,
                    ),

                    SizedBox(height: 1.5.h),

                    // Contact School Section
                    Text(
                      'Contact School',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    SizedBox(height: 1.5.h),

                    // School Phone Button
                    ElevatedButton.icon(
                      onPressed: () => _makePhoneCall('+254718073907'),
                      icon: const Icon(Icons.phone, size: 20),
                      label: const Text(
                        'Call School',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.4.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
