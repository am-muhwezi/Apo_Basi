import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/location_config.dart';
import '../../config/mapbox_helpers.dart';
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
  ll.LatLng? _homeLocation; // Child's home location (static, not GPS)
  bool _isLoadingLocation = true;
  final HomeLocationService _homeLocationService = HomeLocationService();

  // Mapbox Maps SDK
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  PointAnnotation? _homeAnnotation;
  PointAnnotation? _busAnnotation;
  PolylineAnnotation? _routeAnnotation;

  // Pre-rendered marker images
  Uint8List? _homeMarkerImage;
  Uint8List? _busMarkerImage;

  // Real-time bus tracking
  final BusWebSocketService _webSocketService = BusWebSocketService();
  BusLocation? _busLocation;
  ll.LatLng? _snappedBusLocation; // Road-snapped bus location
  LocationConnectionState _connectionState =
      LocationConnectionState.disconnected;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectionSubscription;

  // ETA and Route Information
  int? _etaMinutes;
  List<ll.LatLng>? _routePoints;
  String? _distance;
  bool _isCalculatingETA = false;

  @override
  void initState() {
    super.initState();
    _loadMarkerImages();
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
    super.dispose();
  }

  /// Load marker images from assets
  Future<void> _loadMarkerImages() async {
    // Load bus marker image
    try {
      final ByteData busBytes =
          await rootBundle.load('assets/images/Bus 2.png');
      _busMarkerImage = busBytes.buffer.asUint8List();
    } catch (e) {
      // Bus image not found, will skip bus marker
    }

    // Create home marker image programmatically (blue circle with home icon)
    _homeMarkerImage = await _createHomeMarkerImage();
  }

  /// Create a home marker icon image programmatically
  Future<Uint8List> _createHomeMarkerImage() async {
    const double size = 96; // 48 logical * 2 for retina
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // Draw blue circle
    final paint = Paint()..color = const Color(0xFF2B5CE6);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, paint);

    // Draw white inner circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 3.5, innerPaint);

    // Draw house icon (simple)
    final iconPaint = Paint()
      ..color = const Color(0xFF2B5CE6)
      ..style = PaintingStyle.fill;
    final path = Path();
    // Roof
    path.moveTo(size / 2, size * 0.3);
    path.lineTo(size * 0.35, size * 0.48);
    path.lineTo(size * 0.65, size * 0.48);
    path.close();
    canvas.drawPath(path, iconPaint);
    // Body
    canvas.drawRect(
      Rect.fromLTWH(size * 0.38, size * 0.48, size * 0.24, size * 0.2),
      iconPaint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Called when the Mapbox map is created and ready
  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Create annotation managers
    _pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    // Place initial markers
    _updateHomeAnnotation();
    _updateBusAnnotation();
    _updateRouteAnnotation();

    // Center on initial position
    _centerMapOnInitialPosition();
  }

  /// Center map on bus (if available) or home location
  void _centerMapOnInitialPosition() {
    if (_mapboxMap == null) return;

    if (_busLocation != null) {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: latLngToPoint(ll.LatLng(
            _busLocation!.latitude,
            _busLocation!.longitude,
          )),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 500),
      );
    } else if (_homeLocation != null) {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: latLngToPoint(_homeLocation!),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 500),
      );
    }
  }

  /// Update the home marker annotation
  Future<void> _updateHomeAnnotation() async {
    if (_pointAnnotationManager == null ||
        _homeLocation == null ||
        _homeMarkerImage == null) return;

    // Delete existing
    if (_homeAnnotation != null) {
      await _pointAnnotationManager!.delete(_homeAnnotation!);
      _homeAnnotation = null;
    }

    // Create new
    _homeAnnotation = await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: latLngToPoint(_homeLocation!),
        image: _homeMarkerImage,
        iconSize: 0.5,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );
  }

  /// Update the bus marker annotation
  Future<void> _updateBusAnnotation() async {
    if (_pointAnnotationManager == null || _busMarkerImage == null) return;

    if (_busLocation == null) {
      // Remove bus marker if no location
      if (_busAnnotation != null) {
        await _pointAnnotationManager!.delete(_busAnnotation!);
        _busAnnotation = null;
      }
      return;
    }

    final busLatLng = _snappedBusLocation ??
        ll.LatLng(_busLocation!.latitude, _busLocation!.longitude);
    final heading = _busLocation!.heading ?? 0;

    if (_busAnnotation != null) {
      // Update existing annotation
      _busAnnotation!.geometry = latLngToPoint(busLatLng);
      _busAnnotation!.iconRotate = heading;
      await _pointAnnotationManager!.update(_busAnnotation!);
    } else {
      // Create new
      _busAnnotation = await _pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: latLngToPoint(busLatLng),
          image: _busMarkerImage,
          iconSize: 0.4,
          iconRotate: heading,
          iconAnchor: IconAnchor.CENTER,
        ),
      );
    }
  }

  /// Update the route polyline annotation on the map
  Future<void> _updateRouteAnnotation() async {
    if (_polylineAnnotationManager == null) return;

    // Delete existing route
    if (_routeAnnotation != null) {
      await _polylineAnnotationManager!.delete(_routeAnnotation!);
      _routeAnnotation = null;
    }

    // Create new route if we have points
    if (_routePoints != null && _routePoints!.isNotEmpty) {
      _routeAnnotation = await _polylineAnnotationManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: latLngListToPositions(_routePoints!),
          ),
          lineColor: const Color(0xFF5B7FFF).toARGB32(),
          lineWidth: 5.0,
        ),
      );
    }
  }

  /// Initialize WebSocket connection for real-time bus tracking
  Future<void> _initializeSocketConnection() async {
    try {
      await _webSocketService.connect();

      _connectionSubscription =
          _webSocketService.connectionStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _connectionState = state;
          });
          if (state == LocationConnectionState.connected) {
            _subscribeToBus();
          }
        }
      });

      _locationSubscription =
          _webSocketService.locationUpdateStream.listen((location) {
        if (mounted) {
          setState(() {
            _busLocation = location;
          });
          _updateBusLocationWithSnapping(location);
        }
      }, onError: (error) {
        if (LocationConfig.enableSocketLogging) {}
      });

      if (_webSocketService.isConnected) {
        _subscribeToBus();
      } else {
        _subscribeToBus();
      }
    } catch (e) {
      // Failed to initialize WebSocket
    }
  }

  /// Subscribe to bus location updates
  void _subscribeToBus() {
    if (_childData == null) return;

    final busValue = _childData!['busId'];
    if (busValue == null) return;

    final busId =
        busValue is int ? busValue : int.tryParse(busValue.toString());
    if (busId == null) return;

    _webSocketService.subscribeToBus(busId);
  }

  /// Update bus location with road snapping and ETA calculation
  Future<void> _updateBusLocationWithSnapping(BusLocation location) async {
    if (_homeLocation == null) return;

    setState(() {
      _isCalculatingETA = true;
    });

    try {
      final busCoord = ll.LatLng(location.latitude, location.longitude);
      final homeCoord =
          ll.LatLng(_homeLocation!.latitude, _homeLocation!.longitude);

      final snappedCoord = await MapboxRouteService.snapSinglePointToRoad(
        coordinate: busCoord,
        radius: 25,
      );

      final tripInfo = await MapboxRouteService.getTripInformation(
        busLocation: snappedCoord ?? busCoord,
        homeLocation: homeCoord,
        profile: 'driving-traffic',
      );

      if (mounted && tripInfo != null) {
        setState(() {
          _snappedBusLocation = snappedCoord;
          _etaMinutes = tripInfo['eta'];
          _distance = tripInfo['distance'];
          _routePoints = tripInfo['route'];
          _isCalculatingETA = false;
        });
        _updateBusAnnotation();
        _updateRouteAnnotation();
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

  /// Load child's home location
  Future<void> _loadHomeLocation() async {
    try {
      ll.LatLng? homeCoords = await _homeLocationService.getHomeCoordinates();

      if (homeCoords == null) {
        final String? savedAddress =
            await _homeLocationService.getHomeAddress();
        if (savedAddress != null && savedAddress.isNotEmpty) {
          bool success = await _homeLocationService
              .setHomeLocationFromAddress(savedAddress);
          if (success) {
            homeCoords = await _homeLocationService.getHomeCoordinates();
          }
        }
      }

      if (homeCoords == null && _childData != null) {
        final String? childAddress =
            _childData!['homeAddress'] ?? _childData!['address'];
        if (childAddress != null &&
            childAddress.isNotEmpty &&
            childAddress != 'Not set') {
          bool success = await _homeLocationService
              .setHomeLocationFromAddress(childAddress);
          if (success) {
            homeCoords = await _homeLocationService.getHomeCoordinates();
          }
        }
      }

      homeCoords ??= const ll.LatLng(-1.286389, 36.817223);

      if (!mounted) return;

      setState(() {
        _homeLocation = homeCoords;
        _isLoadingLocation = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateHomeAnnotation();
        _centerMapOnInitialPosition();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _homeLocation = const ll.LatLng(-1.286389, 36.817223);
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _getTripStatus() {
    final String childName = _childData?['name'] ?? 'Child';
    final String? status = _childData?['status']?.toString().toLowerCase();

    if (status == 'on-bus' ||
        status == 'on_bus' ||
        status == 'picked-up' ||
        status == 'picked_up') {
      if (_busLocation != null) {
        final isMoving = (_busLocation!.speed ?? 0) > 0.5;
        if (!isMoving) return 'Bus Stopped';
        if (_etaMinutes != null) {
          if (_etaMinutes! <= 5) return 'Driver arrives soon';
          if (_etaMinutes! <= 15) return 'Driver on the way';
        }
        return 'Driver on the way';
      }
      return '$childName is on the bus';
    } else if (status == 'at-school' || status == 'at_school') {
      return '$childName is at school';
    } else if (status == 'dropped-off' ||
        status == 'dropped_off' ||
        status == 'home') {
      return '$childName is Home';
    } else {
      return '$childName is Home';
    }
  }

  String _getRouteDisplay() {
    final routeName = _childData?['routeName'] ??
        _childData?['route_name'] ??
        _childData?['route'];
    if (routeName != null && routeName.toString().trim().isNotEmpty) {
      return routeName.toString();
    }
    final routeCode = _childData?['routeCode'] ?? _childData?['route_code'];
    if (routeCode != null && routeCode.toString().trim().isNotEmpty) {
      return routeCode.toString();
    }
    return 'Route not yet assigned';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  bool _isChildEnRoute() {
    final status = (_childData?['status'] ?? '').toString().toLowerCase();
    return status == 'on_bus' ||
        status == 'on-bus' ||
        status == 'picked_up' ||
        status == 'picked-up';
  }

  String _getDriverInitial() {
    final driverName = _childData?['driverName']?.toString() ?? '';
    if (driverName.isNotEmpty) return driverName[0].toUpperCase();
    return 'D';
  }

  /// En route layout: driver avatar (with bus badge) + call icon + plate/route
  Widget _buildEnRouteInfo(ColorScheme colorScheme, bool isDark) {
    final String? busNumber = _childData?['busNumber'];
    final String routeName = _getRouteDisplay();

    return Row(
      children: [
        // Driver avatar with bus badge
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Driver circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : const Color(0xFFE9E7F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getDriverInitial(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              // Bus badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Call icon
        GestureDetector(
          onTap: () => _makePhoneCall('+254718073907'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.onSurface.withValues(alpha: 0.08)
                  : const Color(0xFFF0F0F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone,
              size: 22,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const Spacer(),
        // Plate number + route (right-aligned)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (busNumber != null && busNumber != 'N/A')
              Text(
                busNumber,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              routeName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// At rest layout (home, school, etc.): status icon + message + call school
  Widget _buildAtRestInfo(ColorScheme colorScheme, bool isDark) {
    final status = (_childData?['status'] ?? '').toString().toLowerCase();
    final childName = _childData?['name'] ?? 'Child';
    final firstName = childName.toString().split(' ').first;

    final bool isAtSchool = status == 'at_school' || status == 'at-school';
    final IconData icon = isAtSchool ? Icons.school : Icons.home;
    final Color accentColor =
        isAtSchool ? const Color(0xFF007AFF) : const Color(0xFF22CCB2);
    final String message = isAtSchool
        ? '$firstName is safely at school'
        : '$firstName is safely at home';

    return Row(
      children: [
        // Status icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: accentColor),
        ),
        const SizedBox(width: 14),
        // Status message
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getRouteDisplay(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Call school
        GestureDetector(
          onTap: () => _makePhoneCall('+254718073907'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.onSurface.withValues(alpha: 0.08)
                  : const Color(0xFFF0F0F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone,
              size: 22,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_childData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No child data available')),
      );
    }

    final bool hasAssignedBus = _childData!['busId'] != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Mapbox Map - native vector rendering with Studio styles
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : _homeLocation != null
                  ? MapWidget(
                      styleUri:
                          'mapbox://styles/${ApiConfig.mapboxStyleId}',
                      cameraOptions: CameraOptions(
                        center: latLngToPoint(_homeLocation!),
                        zoom: 16.0,
                      ),
                      onMapCreated: _onMapCreated,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off,
                              size: 64, color: colorScheme.error),
                          SizedBox(height: 2.h),
                          Text('Unable to get location',
                              style: textTheme.titleLarge),
                          SizedBox(height: 1.h),
                          Text('Please enable location permissions',
                              style: textTheme.bodyMedium),
                        ],
                      ),
                    ),

          // Clean top UI - back button and recenter button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
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
                      icon: Icon(Icons.arrow_back,
                          color: colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
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
                      icon: Icon(Icons.my_location,
                          color: colorScheme.primary),
                      onPressed: () {
                        if (_busLocation != null) {
                          _mapboxMap?.flyTo(
                            CameraOptions(
                              center: latLngToPoint(ll.LatLng(
                                _busLocation!.latitude,
                                _busLocation!.longitude,
                              )),
                              zoom: 16.0,
                            ),
                            MapAnimationOptions(duration: 800),
                          );
                        } else if (_homeLocation != null) {
                          _mapboxMap?.flyTo(
                            CameraOptions(
                              center: latLngToPoint(_homeLocation!),
                              zoom: 16.0,
                            ),
                            MapAnimationOptions(duration: 800),
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

          // Bottom detail sheet
          DraggableScrollableSheet(
            initialChildSize: 0.22,
            minChildSize: 0.18,
            maxChildSize: 0.45,
            builder: (context, scrollController) {
              final isDark = theme.brightness == Brightness.dark;
              final bool isEnRoute = _isChildEnRoute();

              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Status row + ETA pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getTripStatus(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isEnRoute && _etaMinutes != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_etaMinutes mins',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),

                    // Dynamic content based on status
                    if (isEnRoute)
                      _buildEnRouteInfo(colorScheme, isDark)
                    else
                      _buildAtRestInfo(colorScheme, isDark),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
