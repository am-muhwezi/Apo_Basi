import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:latlong2/latlong.dart' as ll;
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/location_config.dart';
import '../../config/mapbox_helpers.dart';
import '../../models/bus_location_model.dart';
import '../../services/bus_websocket_service.dart';
import '../../services/mapbox_optimization_service.dart';
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
  PointAnnotationManager? _homeAnnotationManager;
  PointAnnotationManager? _busAnnotationManager;
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

  // Multi-stop route optimization
  OptimizedRoute? _optimizedRoute;
  int _thisChildStopIndex = -1; // index in _optimizedRoute.orderedStops
  String _tripType = 'dropoff'; // 'pickup' or 'dropoff'
  // Monotonically-advancing pointer: the first stop the bus has NOT yet visited.
  // Only ever moves forward, never back, so past stops are never re-included.
  int _nextStopIndex = 0;

  // Fallback multi-stop routing (used when optimization service fails)
  bool _hasActiveTrip = false;
  List<BusStop> _busStops = [];
  int _stopsBeforeChild = 0;

  @override
  void initState() {
    super.initState();
    _loadMarkerImages();
    // Defer WebSocket connection and route optimization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketConnection();
      _initializeRouteOptimization();
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
    // Invalidate the cached optimized route for this bus
    final busValue = _childData?['busId'];
    if (busValue != null) {
      final busId = busValue is int ? busValue : int.tryParse(busValue.toString());
      if (busId != null) MapboxOptimizationService.invalidate(busId);
    }
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

    // Render home pin using a standard Material icon
    _homeMarkerImage = await _renderPinIcon(icon: Icons.home_rounded);
  }

  /// Renders a Material [icon] onto a standard teardrop map-pin and returns
  /// PNG bytes suitable for [PointAnnotationOptions.image].
  ///
  /// Uses Flutter's built-in Material Icons font via [TextPainter] — no custom
  /// path drawing required. Swap the icon for any [Icons.xxx] constant.
  ///
  /// Canvas: 96 × 124 px (2× retina → 48 × 62 logical pts).
  /// Use [iconAnchor: IconAnchor.BOTTOM] so the pin tip sits on the coordinate.
  Future<Uint8List> _renderPinIcon({
    required IconData icon,
    Color pinColor = const Color(0xFF2B5CE6),
    Color iconColor = Colors.white,
  }) async {
    const double w = 96.0;
    const double h = 124.0;
    const double r = 40.0;
    const double cx = w / 2;
    const double cy = r + 6;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // White outline ring — ensures visibility against any map tile colour
    canvas.drawCircle(Offset(cx, cy), r + 3, Paint()..color = Colors.white);

    // Pin head
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = pinColor);

    // Tapered pin tip (quadratic bezier curves)
    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.44, cy + r * 0.62)
        ..quadraticBezierTo(cx - 5, h - 22, cx, h - 3)
        ..quadraticBezierTo(cx + 5, h - 22, cx + r * 0.44, cy + r * 0.62)
        ..close(),
      Paint()..color = pinColor,
    );

    // Icon glyph — paint the Material icon font character onto the pin head
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: r * 1.15,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
          height: 1.0,
        ),
      )
      ..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 - 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Called when the Mapbox map is created and ready
  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Separate managers so home and bus can have independent sizing
    _homeAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _busAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    // Make bus icon scale with zoom: small when zoomed out, full-size when close
    await _mapboxMap!.style.setStyleLayerProperty(
      _busAnnotationManager!.id,
      'icon-size',
      jsonDecode('["interpolate",["linear"],["zoom"],10,0.015,14,0.04,17,0.10]'),
    );

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
    if (_homeAnnotationManager == null ||
        _homeLocation == null ||
        _homeMarkerImage == null) return;

    // Delete existing
    if (_homeAnnotation != null) {
      await _homeAnnotationManager!.delete(_homeAnnotation!);
      _homeAnnotation = null;
    }

    // Create new — larger than regular POIs so it's always easy to find
    _homeAnnotation = await _homeAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: latLngToPoint(_homeLocation!),
        image: _homeMarkerImage,
        iconSize: 1.2,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );
  }

  /// Update the bus marker annotation
  Future<void> _updateBusAnnotation() async {
    if (_busAnnotationManager == null || _busMarkerImage == null) return;

    if (_busLocation == null) {
      // Remove bus marker if no location
      if (_busAnnotation != null) {
        await _busAnnotationManager!.delete(_busAnnotation!);
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
      await _busAnnotationManager!.update(_busAnnotation!);
    } else {
      // Create new — iconSize is intentionally omitted so the zoom expression controls it
      _busAnnotation = await _busAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: latLngToPoint(busLatLng),
          image: _busMarkerImage,
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

  /// Update bus location with road snapping and multi-stop ETA calculation.
  ///
  /// Uses the optimized stop order when available; falls back to the direct
  /// 2-point route so the screen always shows something meaningful.
  Future<void> _updateBusLocationWithSnapping(BusLocation location) async {
    if (_homeLocation == null) return;

    setState(() {
      _isCalculatingETA = true;
    });

    try {
      final busCoord = ll.LatLng(location.latitude, location.longitude);

      final snappedCoord = await MapboxRouteService.snapSinglePointToRoad(
        coordinate: busCoord,
        radius: 25,
      );
      final effectiveBus = snappedCoord ?? busCoord;

      Map<String, dynamic>? tripInfo;

      // --- Multi-stop path ---------------------------------------------------
      if (_optimizedRoute != null && _thisChildStopIndex >= 0) {
        final stops = _optimizedRoute!.orderedStops;

        // Advance _nextStopIndex forward whenever the bus is within 200 m of
        // the current next stop — this is monotonic (never goes backward) so
        // a stop is never re-added to the waypoint list after it's been visited.
        while (_nextStopIndex < stops.length) {
          final distToNext = _haversineKm(effectiveBus, stops[_nextStopIndex].homeLatLng);
          if (distToNext < 0.2) {
            // Bus is within 200 m — consider this stop reached, advance pointer
            setState(() => _nextStopIndex++);
          } else {
            break;
          }
        }

        // If this child's stop has already been passed, show arrived
        if (_thisChildStopIndex < _nextStopIndex) {
          if (mounted) {
            setState(() {
              _snappedBusLocation = snappedCoord;
              _etaMinutes = 0;
              _isCalculatingETA = false;
            });
            _updateBusAnnotation();
          }
          return;
        }

        // Build waypoints: bus → _nextStopIndex → ... → _thisChildStopIndex
        final waypoints = <ll.LatLng>[effectiveBus];
        for (int i = _nextStopIndex; i <= _thisChildStopIndex; i++) {
          waypoints.add(stops[i].homeLatLng);
        }


        if (waypoints.length > 1) {
          tripInfo = await MapboxRouteService.getMultiWaypointTripInformation(
            waypoints: waypoints,
            profile: 'driving-traffic',
          );
        }
      }

      // --- Fallback: use stored bus stops when optimization is unavailable ---
      if (tripInfo == null && _busStops.length >= 2) {
        final waypoints = _buildFallbackWaypoints(effectiveBus);
        if (waypoints != null && waypoints.length >= 2) {
          tripInfo = await MapboxRouteService.getMultiWaypointTripInformation(
            waypoints: waypoints,
            profile: 'driving-traffic',
          );
        }
      }

      // --- Direct-route fallback -------------------------------------------
      tripInfo ??= await MapboxRouteService.getTripInformation(
        busLocation: effectiveBus,
        homeLocation: _homeLocation!,
        profile: 'driving-traffic',
      );

      if (mounted && tripInfo != null) {
        setState(() {
          _snappedBusLocation = snappedCoord;
          _etaMinutes = tripInfo!['eta'];
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
    } catch (_) {
      setState(() {
        _isCalculatingETA = false;
      });
    }
  }

  /// Haversine distance in km (used to find nearest stop to bus position).
  double _haversineKm(ll.LatLng a, ll.LatLng b) {
    const r = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final h = sinDLat * sinDLat +
        cos(_deg2rad(a.latitude)) * cos(_deg2rad(b.latitude)) * sinDLon * sinDLon;
    return 2 * r * asin(sqrt(h));
  }

  double _deg2rad(double deg) => deg * pi / 180.0;

  /// Fetch the active trip type and all sibling stops, then run optimization.
  /// Called once on screen load; result cached by [MapboxOptimizationService].
  Future<void> _initializeRouteOptimization() async {
    if (_childData == null) return;

    final busValue = _childData!['busId'];
    if (busValue == null) return;
    final busId = busValue is int ? busValue : int.tryParse(busValue.toString());
    if (busId == null) return;

    try {
      // 1. Determine trip type from active trip, fall back to time-of-day
      _tripType = await _getActiveTripType(busId);

      // 2. Fetch all children on this bus that have home coordinates set
      final busStops = await _fetchBusStops(busId);

      // Store stops so the fallback multi-stop router can use them
      if (mounted) {
        setState(() {
          _busStops = busStops;
          _hasActiveTrip = true;
        });
      }

      // Need at least 2 stops for multi-stop routing to be meaningful
      if (busStops.length < 2) {
        return;
      }

      // 3. Read school coordinates from .env (always present)
      final schoolCoords = _getSchoolCoordinates();
      if (schoolCoords == null) {
        return;
      }

      final optimized = await MapboxOptimizationService.optimizeRoute(
        busId: busId,
        schoolLocation: schoolCoords,
        busStops: busStops,
        tripType: _tripType,
      );
      if (optimized == null || !mounted) return;

      // 4. Find this child's stop index in the optimized order
      final thisChildId = _childData!['id'] is int
          ? _childData!['id'] as int
          : int.tryParse(_childData!['id'].toString()) ?? -1;

      int stopIdx = optimized.orderedStops
          .indexWhere((s) => s.childId == thisChildId);


      // If this child has no home coords in the DB (not in orderedStops),
      // treat all optimized stops as intermediate waypoints and append
      // _homeLocation as the final destination.
      if (stopIdx == -1 && _homeLocation != null) {
        final extendedStops = [
          ...optimized.orderedStops,
          BusStop(childId: thisChildId, homeLatLng: _homeLocation!),
        ];
        final extendedDurations = [...optimized.legDurations, 0.0];
        final extended = OptimizedRoute(
          orderedStops: extendedStops,
          legDurations: extendedDurations,
        );
        stopIdx = extendedStops.length - 1;
        if (!mounted) return;
        setState(() {
          _optimizedRoute = extended;
          _thisChildStopIndex = stopIdx;
          _nextStopIndex = 0;
          _stopsBeforeChild = stopIdx; // all other stops come first
        });
        if (_busLocation != null) {
          _updateBusLocationWithSnapping(_busLocation!);
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _optimizedRoute = optimized;
        _thisChildStopIndex = stopIdx;
        _nextStopIndex = 0; // reset pointer for this fresh route
        _stopsBeforeChild = stopIdx > 0 ? stopIdx : 0;
      });

      // CRITICAL: Re-trigger ETA now that we have the optimized route.
      // The WebSocket may have already fired before optimization completed,
      // so the first ETA was calculated using the direct-route fallback.
      // Recalculate immediately with the correct multi-stop waypoints.
      if (_busLocation != null) {
        _updateBusLocationWithSnapping(_busLocation!);
      }
    } catch (_) {
      // Direct-route ETA fallback remains in place
    }
  }

  /// Build ordered waypoints [bus, stop1, ..., thisChildHome] using stored
  /// [_busStops] when [_optimizedRoute] is unavailable or the Directions API
  /// transiently failed.
  ///
  /// Ordering rules (mirrors Mapbox Optimization logic):
  ///   pickup  → farthest from school first (bus heads outward, comes back)
  ///   dropoff → nearest to school first (bus delivers closest kids first)
  ///
  /// Skips stops the bus has already passed (within 200 m).
  /// Does NOT update [_stopsBeforeChild] — that value is owned by
  /// [_initializeRouteOptimization] so we never overwrite the correct count.
  List<ll.LatLng>? _buildFallbackWaypoints(ll.LatLng busLocation) {
    if (_busStops.isEmpty) return null;

    final thisChildId = _childData?['id'] is int
        ? _childData!['id'] as int
        : int.tryParse(_childData?['id']?.toString() ?? '') ?? -1;
    if (thisChildId == -1) return null;

    // Filter out stops already passed by the bus (within 200 m)
    final remaining = _busStops
        .where((s) => _haversineKm(busLocation, s.homeLatLng) > 0.2)
        .toList();
    if (remaining.isEmpty) return null;

    // Sort by school distance: school coords are always available from .env
    final school = _getSchoolCoordinates();
    if (school != null) {
      remaining.sort((a, b) {
        final dA = _haversineKm(school, a.homeLatLng);
        final dB = _haversineKm(school, b.homeLatLng);
        // pickup → farthest first (descending); dropoff → nearest first (ascending)
        return _tripType == 'pickup'
            ? dB.compareTo(dA)
            : dA.compareTo(dB);
      });
    }

    // Find this child's position in the sorted list
    final thisChildIdx = remaining.indexWhere((s) => s.childId == thisChildId);
    if (thisChildIdx == -1) return null;

    // Waypoints: bus → stops[0..thisChildIdx] inclusive
    final waypoints = <ll.LatLng>[busLocation];
    for (int i = 0; i <= thisChildIdx; i++) {
      waypoints.add(remaining[i].homeLatLng);
    }
    return waypoints;
  }

  /// Return school GPS coordinates from the .env file.
  /// SCHOOL_LATITUDE and SCHOOL_LONGITUDE are always present in .env.
  ll.LatLng? _getSchoolCoordinates() {
    final lat = ApiConfig.schoolLatitude;
    final lng = ApiConfig.schoolLongitude;
    if (lat != null && lng != null) return ll.LatLng(lat, lng);
    return null;
  }

  /// GET /api/trips/?bus_id=X&status=in-progress — returns 'pickup' or 'dropoff'.
  Future<String> _getActiveTripType(int busId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBaseUrl}/api/trips/?bus_id=$busId&status=in-progress',
      );
      final token = await _getAuthToken();
      final response = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? data as List? ?? [];
        if (results.isNotEmpty) {
          final tripType = results[0]['type']?.toString() ?? '';
          if (tripType == 'pickup' || tripType == 'dropoff') return tripType;
        }
      }
    } catch (_) {}

    // Time-of-day heuristic: before noon → pickup, after noon → dropoff
    return DateTime.now().hour < 12 ? 'pickup' : 'dropoff';
  }

  /// GET /api/buses/{busId}/children/ and build the list of [BusStop]s.
  Future<List<BusStop>> _fetchBusStops(int busId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBaseUrl}${ApiConfig.busChildrenEndpoint(busId)}',
      );
      final token = await _getAuthToken();
      final response = await http.get(
        uri,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final children = data['children'] as List? ?? [];

        final stops = <BusStop>[];
        for (final child in children) {
          final lat = (child['homeLatitude'] as num?)?.toDouble();
          final lng = (child['homeLongitude'] as num?)?.toDouble();
          final id = child['id'] as int?;
          if (lat != null && lng != null && id != null) {
            stops.add(BusStop(childId: id, homeLatLng: ll.LatLng(lat, lng)));
          }
        }
        return stops;
      }
    } catch (_) {}
    return [];
  }

  /// Read the JWT access token from SharedPreferences.
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (_) {
      return null;
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
    final String firstName = childName.split(' ').first;
    final String? status = _childData?['status']?.toString().toLowerCase();

    if (status == 'on-bus' ||
        status == 'on_bus' ||
        status == 'picked-up' ||
        status == 'picked_up') {
      if (_busLocation != null) {
        final isMoving = (_busLocation!.speed ?? 0) > 0.5;
        if (!isMoving) return 'Bus Stopped';
        if (_etaMinutes != null) {
          if (_etaMinutes! <= 3) return 'Bus arrives soon';
          if (_etaMinutes! <= 15) return 'Driver on the way';
        }
        return 'Driver on the way';
      }
      return '$firstName is on the bus';
    } else if (status == 'at-school' || status == 'at_school') {
      return '$firstName is at school';
    } else if (status == 'dropped-off' ||
        status == 'dropped_off' ||
        status == 'home') {
      return '$firstName is Home';
    } else {
      // No terminal status — show trip-in-progress message if bus is active
      if (_hasActiveTrip && _busLocation != null) {
        if (_etaMinutes != null) {
          if (_etaMinutes! <= 3) return 'Bus arrives soon';
          return 'Bus is on its way';
        }
        return 'Bus is on its way';
      }
      return '$firstName is Home';
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
                        // Show ETA whenever bus is active and we have an estimate
                        if (_busLocation != null && _etaMinutes != null && _etaMinutes! > 0)
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
                              '$_etaMinutes min${_etaMinutes! == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Stops-before-this-child indicator
                    if (_busLocation != null && _stopsBeforeChild > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.pin_drop_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_stopsBeforeChild stop${_stopsBeforeChild > 1 ? 's' : ''} before yours',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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
