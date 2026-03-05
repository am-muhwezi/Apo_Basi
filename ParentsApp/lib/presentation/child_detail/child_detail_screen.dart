import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

class _ChildDetailScreenState extends State<ChildDetailScreen>
    with WidgetsBindingObserver {
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
  StreamSubscription? _tripEventSubscription;

  // ETA and Route Information
  int? _etaMinutes;
  List<ll.LatLng>? _routePoints;
  String? _distance;
  bool _isCalculatingETA = false;

  // ETA/route throttle — only re-fetch Directions API every 30 s or 75 m
  DateTime? _lastEtaRefresh;
  ll.LatLng? _lastEtaPosition;

  // Trip-watcher: polls while no bus is broadcasting to detect trip start
  Timer? _tripWatchTimer;

  // Smooth bus position animation (Mapbox Maps SDK annotation interpolation)
  Timer? _busAnimTimer;
  ll.LatLng? _busAnimFrom;
  ll.LatLng? _busAnimTo;
  double _busAnimFromHeading = 0;
  double _busAnimToHeading = 0;

  // Single source of truth for trip state — set exclusively by WebSocket events
  bool _hasActiveTrip = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMarkerImages();
    // Defer WebSocket connection to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocketConnection();
      _startTripWatcher();
    });
  }

  /// Reconnect immediately when the app comes back to the foreground instead
  /// of waiting up to 15 s for the next TripWatcher cycle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_childData == null) return;
    final busValue = _childData!['busId'];
    if (busValue == null) return;
    final busId =
        busValue is int ? busValue : int.tryParse(busValue.toString());
    if (busId == null) return;

    if (!_webSocketService.isConnected) {
      _webSocketService.subscribeToBus(busId);
    } else {
      // Already connected — request a fresh trip_state snapshot.
      _webSocketService.requestTripState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _childData = args;
    }
    _loadHomeLocation();
    // Do NOT call _subscribeToBus() here — _initializeSocketConnection()
    // handles it in the postFrameCallback and calling it here creates an
    // orphan WebSocket connection before the stream listeners are set up.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tripWatchTimer?.cancel();
    _busAnimTimer?.cancel();
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _tripEventSubscription?.cancel();
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
      jsonDecode(
          '["interpolate",["linear"],["zoom"],10,0.015,14,0.04,17,0.10]'),
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

  /// Update the bus marker annotation, animating smoothly from the previous
  /// position to the new one (1 second, ease-in-out, ~30 fps).
  Future<void> _updateBusAnnotation() async {
    if (_busAnnotationManager == null || _busMarkerImage == null) return;

    if (_busLocation == null) {
      _busAnimTimer?.cancel();
      if (_busAnnotation != null) {
        await _busAnnotationManager!.delete(_busAnnotation!);
        _busAnnotation = null;
      }
      return;
    }

    final targetLatLng = _snappedBusLocation ??
        ll.LatLng(_busLocation!.latitude, _busLocation!.longitude);
    final targetHeading = (_busLocation!.heading ?? 0).toDouble();

    if (_busAnnotation == null) {
      // First appearance — create annotation and fly the camera to the bus
      // so the parent sees it immediately, even if home is far away.
      _busAnnotation = await _busAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: latLngToPoint(targetLatLng),
          image: _busMarkerImage,
          iconRotate: targetHeading,
          iconAnchor: IconAnchor.CENTER,
        ),
      );
      _busAnimFrom = targetLatLng;
      _busAnimFromHeading = targetHeading;
      _mapboxMap?.flyTo(
        CameraOptions(
          center: latLngToPoint(targetLatLng),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 800),
      );
      return;
    }

    // Animate from previous position to new position
    _busAnimTimer?.cancel();
    final fromLatLng = _busAnimFrom ?? targetLatLng;
    final fromHeading = _busAnimFromHeading;

    // Shortest-path heading delta (handles 0↔360 wraparound)
    double headingDiff = targetHeading - fromHeading;
    if (headingDiff > 180) headingDiff -= 360;
    if (headingDiff < -180) headingDiff += 360;

    const totalFrames = 30;
    int frame = 0;
    _busAnimTimer = Timer.periodic(const Duration(milliseconds: 33), (t) async {
      frame++;
      final rawT = frame / totalFrames;
      if (rawT >= 1.0) {
        t.cancel();
      }
      final easedT = _easeInOut(rawT.clamp(0.0, 1.0));

      final lat = fromLatLng.latitude +
          (targetLatLng.latitude - fromLatLng.latitude) * easedT;
      final lng = fromLatLng.longitude +
          (targetLatLng.longitude - fromLatLng.longitude) * easedT;
      final heading = fromHeading + headingDiff * easedT;

      if (_busAnnotation != null && _busAnnotationManager != null && mounted) {
        _busAnnotation!.geometry = latLngToPoint(ll.LatLng(lat, lng));
        _busAnnotation!.iconRotate = heading;
        // Fire-and-forget: don't await to avoid blocking the timer
        _busAnnotationManager!.update(_busAnnotation!);
      }
    });

    _busAnimFrom = targetLatLng;
    _busAnimFromHeading = targetHeading;
  }

  /// Ease-in-out curve: smooth acceleration and deceleration.
  double _easeInOut(double t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

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
      // Cancel any existing subscriptions before setting up new ones.
      // Guards against duplicate listeners if this is ever called more than once.
      _locationSubscription?.cancel();
      _connectionSubscription?.cancel();
      _tripEventSubscription?.cancel();

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
        if (!mounted) return;
        if (!_hasActiveTrip) {
          // No active trip — ignore all location updates (covers both the
          // "trip just ended" case and the "no trip on screen open" case).
          return;
        }

        setState(() {
          _busLocation = location;
        });
        _updateBusLocationWithSnapping(location);
      }, onError: (error) {
        if (LocationConfig.enableSocketLogging) {}
      });

      // Server pushes trip_state (on connect), trip_started, and trip_ended
      // over the same channel.  The UI is a pure slave to these events —
      // no HTTP polling for trip type is ever needed.
      _tripEventSubscription =
          _webSocketService.tripEventStream.listen((event) {
        if (!mounted) return;
        final eventType = event['type'] as String?;

        if (eventType == 'trip_state') {
          // ── Sent by the server immediately on every (re)connect ──────────
          final hasActiveTrip = event['has_active_trip'] as bool? ?? false;
          debugPrint('[TripEvent] trip_state: has_active_trip=$hasActiveTrip');

          if (!hasActiveTrip) {
            setState(() {
              _hasActiveTrip = false;
            });
            return;
          }

          setState(() {
            _hasActiveTrip = true;
          });

          // Seed the map with the last known bus position from the DB so the
          // marker appears instantly, before the next live GPS update arrives.
          final lat = event['bus_latitude'];
          final lng = event['bus_longitude'];
          if (lat != null && lng != null && _busLocation == null) {
            final busValue = _childData?['busId'];
            final busId = busValue is int
                ? busValue
                : int.tryParse(busValue?.toString() ?? '');
            if (busId != null) {
              final seedLocation = BusLocation(
                busId: busId,
                busNumber: '',
                latitude: (lat as num).toDouble(),
                longitude: (lng as num).toDouble(),
                speed: (event['bus_speed'] as num?)?.toDouble() ?? 0.0,
                heading: (event['bus_heading'] as num?)?.toDouble() ?? 0.0,
                isActive: true,
                timestamp: DateTime.now(),
              );
              setState(() => _busLocation = seedLocation);
              _updateBusAnnotation();
              // Kick off route/ETA immediately from seed GPS.
              _updateBusLocationWithSnapping(seedLocation);
            }
          }

        } else if (eventType == 'trip_started') {
          debugPrint('[TripEvent] trip_started');
          setState(() {
            _hasActiveTrip = true;
          });

          // Seed map with last known GPS so the bus marker appears immediately
          final lat = event['bus_latitude'];
          final lng = event['bus_longitude'];
          if (lat != null && lng != null && _busLocation == null) {
            final busValue = _childData?['busId'];
            final busId = busValue is int
                ? busValue
                : int.tryParse(busValue?.toString() ?? '');
            if (busId != null) {
              final seedLocation = BusLocation(
                busId: busId,
                busNumber: '',
                latitude: (lat as num).toDouble(),
                longitude: (lng as num).toDouble(),
                speed: (event['bus_speed'] as num?)?.toDouble() ?? 0.0,
                heading: (event['bus_heading'] as num?)?.toDouble() ?? 0.0,
                isActive: true,
                timestamp: DateTime.now(),
              );
              setState(() => _busLocation = seedLocation);
              _updateBusAnnotation();
              // Kick off route/ETA immediately from seed — don't wait for
              // the first real GPS update which may take several seconds.
              _updateBusLocationWithSnapping(seedLocation);
            }
          }

        } else if (eventType == 'trip_ended') {
          debugPrint('[TripEvent] trip_ended — clearing trip state');
          if (mounted) {
            setState(() {
              _hasActiveTrip = false;
              _busLocation = null;
              _etaMinutes = null;
              _routePoints = null;
              // Reset throttle so the next trip's first GPS update always
              // triggers an immediate route+ETA computation.
              _lastEtaRefresh = null;
              _lastEtaPosition = null;
            });
            _updateBusAnnotation();
            _updateRouteAnnotation();
          }
        }
      });

      _subscribeToBus();
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

  /// Update bus location and recompute route/ETA when needed.
  ///
  /// The server pre-snaps GPS to road before broadcasting, so no client-side
  /// Map Matching call is required — only the Directions API is called here.
  Future<void> _updateBusLocationWithSnapping(BusLocation location) async {
    if (_homeLocation == null) return;
    if (!_hasActiveTrip) return;
    try {
      final busCoord = ll.LatLng(location.latitude, location.longitude);
      // Use server-snapped position when available; fall back to raw GPS.
      final snappedCoord =
          (location.snappedLatitude != null && location.snappedLongitude != null)
              ? ll.LatLng(location.snappedLatitude!, location.snappedLongitude!)
              : null;
      final routeOrigin = snappedCoord ?? busCoord;
      final now = DateTime.now();

      // Throttle: only recompute route every 30 s or 75 m of movement.
      bool shouldRefreshEta = false;
      if (_lastEtaRefresh == null || _lastEtaPosition == null) {
        shouldRefreshEta = true;
      } else {
        final elapsed = now.difference(_lastEtaRefresh!).inSeconds;
        final movedKm = _haversineKm(busCoord, _lastEtaPosition!);
        if (elapsed >= 30 || movedKm >= 0.075) shouldRefreshEta = true;
      }

      if (!shouldRefreshEta) {
        // No route recompute — just update the bus marker position.
        if (mounted) {
          setState(() {
            _snappedBusLocation = snappedCoord;
            _isCalculatingETA = false;
          });
          _updateBusAnnotation();
        }
        return;
      }

      if (mounted) setState(() => _isCalculatingETA = true);

      // Single Directions API call — server already handled road snapping.
      Map<String, dynamic>? tripInfo =
          await MapboxRouteService.getTripInformation(
        busLocation: routeOrigin,
        homeLocation: _homeLocation!,
        profile: 'driving-traffic',
      );
      if (!mounted || !_hasActiveTrip) return;

      // Fallback to plain driving if traffic profile failed.
      tripInfo ??= await MapboxRouteService.getTripInformation(
        busLocation: routeOrigin,
        homeLocation: _homeLocation!,
        profile: 'driving',
      );
      if (!mounted || !_hasActiveTrip) return;

      debugPrint(
          '[Route] tripInfo=${tripInfo != null ? "ok eta=${tripInfo['eta']}" : "null"}');

      if (tripInfo != null) {
        setState(() {
          _snappedBusLocation = snappedCoord;
          _etaMinutes = tripInfo!['eta'];
          _distance = tripInfo['distance'];
          _routePoints = tripInfo['route'];
          _isCalculatingETA = false;
          _lastEtaRefresh = now;
          _lastEtaPosition = busCoord;
        });
        _updateBusAnnotation();
        _updateRouteAnnotation();
      } else {
        // Don't poison the throttle on failure — retry on next GPS update.
        setState(() => _isCalculatingETA = false);
      }
    } catch (e) {
      debugPrint('[Route] error: $e');
      setState(() => _isCalculatingETA = false);
    }
  }

  /// Haversine distance in km (used to throttle ETA refresh by bus movement).
  double _haversineKm(ll.LatLng a, ll.LatLng b) {
    const r = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final h = sinDLat * sinDLat +
        cos(_deg2rad(a.latitude)) *
            cos(_deg2rad(b.latitude)) *
            sinDLon *
            sinDLon;
    return 2 * r * asin(sqrt(h));
  }

  double _deg2rad(double deg) => deg * pi / 180.0;

  /// WebSocket health check — fires every 15 s.
  ///
  /// Two modes:
  ///  • No active trip:  force disconnect+reconnect every cycle so the server
  ///    sends a fresh trip_state.  This handles zombie TCP connections (client
  ///    thinks it's connected but the server can't reach it) and missed
  ///    trip_started events.
  ///  • Active trip:     only reconnect if offline — avoids interrupting the
  ///    live GPS stream.
  void _startTripWatcher() {
    _tripWatchTimer?.cancel();
    _tripWatchTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      if (_childData == null) return;
      final busValue = _childData!['busId'];
      if (busValue == null) return;
      final busId =
          busValue is int ? busValue : int.tryParse(busValue.toString());
      if (busId == null) return;

      if (!_webSocketService.isConnected) {
        debugPrint('[TripWatcher] WebSocket offline — re-subscribing bus $busId');
        _webSocketService.subscribeToBus(busId);
      } else if (!_hasActiveTrip) {
        // No active trip: force a reconnect so the server sends a fresh
        // trip_state.  This recovers from zombie connections and missed
        // trip_started broadcasts.
        debugPrint('[TripWatcher] No active trip — forcing WS refresh for bus $busId');
        _webSocketService.disconnect();
        _webSocketService.subscribeToBus(busId);
      }
    });
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
    }

    // Active trip overrides stale static status (at-school, home, etc.).
    // The WebSocket trip_state / trip_started events set _hasActiveTrip;
    // don't gate on _busLocation since the GPS marker may not have arrived yet.
    if (_hasActiveTrip) {
      if (_busLocation != null && _etaMinutes != null && _etaMinutes! <= 3) {
        return 'Bus arrives soon';
      }
      return 'Bus is on its way';
    }

    if (status == 'at-school' || status == 'at_school') {
      return '$firstName is at school';
    } else if (status == 'dropped-off' ||
        status == 'dropped_off' ||
        status == 'home') {
      return '$firstName is Home';
    } else {
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
    // WebSocket trip state takes precedence over stale DB status
    if (_hasActiveTrip) return true;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Mapbox Map - native vector rendering with Studio styles
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : _homeLocation != null
                  ? MapWidget(
                      styleUri: 'mapbox://styles/${ApiConfig.mapboxStyleId}',
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
                      icon:
                          Icon(Icons.arrow_back, color: colorScheme.onSurface),
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
                      icon: Icon(Icons.my_location, color: colorScheme.primary),
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
                        if (_etaMinutes != null)
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
