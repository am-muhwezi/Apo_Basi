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
import '../../services/parent_notifications_service.dart';

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
  // Server-pushed ETA stream (bus.eta_update via WebSocket).
  StreamSubscription? _etaSubscription;
  // Attendance notifications — stop map tracking when this child is dropped off.
  StreamSubscription? _attendanceSubscription;

  // ETA and Route Information
  int? _etaMinutes;
  List<ll.LatLng>? _routePoints;
  String? _distance;
  bool _isCalculatingETA = false;

  // ETA/route throttle — only re-fetch Directions API every 30 s or 75 m
  DateTime? _lastEtaRefresh;
  ll.LatLng? _lastEtaPosition;

  // Trip-watcher: reconnects only when genuinely offline or zombie (silent >45 s)
  Timer? _tripWatchTimer;
  // Timestamp of the last WS message — used for zombie-connection detection.
  DateTime? _lastWsMessageAt;

  // Smooth bus position animation (Mapbox Maps SDK annotation interpolation)
  Timer? _busAnimTimer;
  ll.LatLng? _busAnimFrom;
  ll.LatLng? _busAnimTo;
  double _busAnimFromHeading = 0;
  double _busAnimToHeading = 0;

  // Single source of truth for trip state — set exclusively by WebSocket events
  bool _hasActiveTrip = false;
  // Guards against concurrent annotation creation (unawaited async calls race).
  bool _busAnnotationCreating = false;

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
    _etaSubscription?.cancel();
    _attendanceSubscription?.cancel();
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

    // Ensure per-annotation icon-rotate is applied (data-driven expression).
    // Without this, Mapbox may ignore the per-feature rotation value.
    await _mapboxMap!.style.setStyleLayerProperty(
      _busAnnotationManager!.id,
      'icon-rotate',
      jsonDecode('["get", "icon-rotate"]'),
    );
    // Keep rotation absolute (relative to north), not to the camera bearing.
    await _mapboxMap!.style.setStyleLayerProperty(
      _busAnnotationManager!.id,
      'icon-rotation-alignment',
      'map',
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
    // Prefer server-computed bearing (derived from consecutive GPS positions —
    // reliable at low speed) over the raw GPS heading sensor.
    final targetHeading =
        (_busLocation!.bearing ?? _busLocation!.heading ?? 0).toDouble();

    if (_busAnnotation == null) {
      // Guard against concurrent creation: two unawaited calls can both see
      // _busAnnotation == null and create duplicate map annotations.
      if (_busAnnotationCreating) return;
      _busAnnotationCreating = true;

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
      _busAnnotationCreating = false;
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
        _lastWsMessageAt = DateTime.now(); // alive — reset zombie clock
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

        _lastWsMessageAt = DateTime.now(); // alive — reset zombie clock

        if (eventType == 'trip_state') {
          // ── Sent by the server immediately on every (re)connect ──────────
          debugPrint('[TripEvent] trip_state: has_active_trip=${event['has_active_trip']}');
          _applyTripState(event);

        } else if (eventType == 'trip_started') {
          debugPrint('[TripEvent] trip_started');
          // Reuse the same seed+route logic as trip_state.
          _applyTripState({
            'has_active_trip': true,
            'trip_type': event['trip_type'],
            'bus_latitude': event['bus_latitude'],
            'bus_longitude': event['bus_longitude'],
            'bus_speed': event['bus_speed'],
            'bus_heading': event['bus_heading'],
          });

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

      // ── Apply cached trip state immediately ───────────────────────────────
      // The WS service is a singleton. If the user navigated away and back,
      // the last trip_state the server sent is still in memory. Apply it now
      // so the screen shows the correct trip status synchronously instead of
      // showing the blank/no-trip state until the next WS message arrives.
      // Server-computed ETAs (Mapbox Directions, sequential waypoints —
      // trip-type aware: pickup = farthest-stop first; dropoff = nearest first).
      _etaSubscription?.cancel();
      _etaSubscription = _webSocketService.etaUpdateStream.listen((etas) {
        if (!mounted) return;
        final childId =
            _childData?['id']?.toString() ??
            _childData?['childId']?.toString();
        if (childId != null && etas.containsKey(childId)) {
          setState(() =>
              _etaMinutes = (etas[childId]! / 60).round().clamp(0, 9999));
        }
      });

      final cached = _webSocketService.lastTripState;
      if (cached != null && mounted) {
        _applyTripState(cached);
      }

      // When this specific child is dropped off, stop showing the bus on the map.
      _attendanceSubscription?.cancel();
      _attendanceSubscription = ParentNotificationsService()
          .attendanceNotificationStream
          .listen((notification) {
        if (!mounted) return;
        if (notification['notification_type'] != 'dropoff_complete') return;
        final notifChildId = notification['child_id'];
        final currentChildId = _childData?['id'];
        if (notifChildId == null || currentChildId == null) return;
        if (notifChildId.toString() != currentChildId.toString()) return;

        setState(() {
          _hasActiveTrip = false;
          _busLocation = null;
          _etaMinutes = null;
          _routePoints = null;
          _lastEtaRefresh = null;
          _lastEtaPosition = null;
        });
        _updateBusAnnotation();
        _updateRouteAnnotation();
      });

      _subscribeToBus();
    } catch (e) {
      // Failed to initialize WebSocket
    }
  }

  /// Apply a trip_state (or trip_state-shaped) event map to local state.
  /// Used both by the stream listener and by the cached-state restore path.
  void _applyTripState(Map<String, dynamic> event) {
    final hasActiveTrip = event['has_active_trip'] as bool? ?? false;
    final tripType = event['trip_type'] as String?;

    if (!hasActiveTrip) {
      setState(() => _hasActiveTrip = false);
      return;
    }
    setState(() => _hasActiveTrip = true);

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
        _updateBusLocationWithSnapping(seedLocation);
      }
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

    // Provide child name so trip event notifications say e.g. "Yahweh Alpha..."
    final childName = _childData!['name']?.toString() ?? '';
    if (childName.isNotEmpty) {
      _webSocketService.setChildName(childName);
    }
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
        final info = tripInfo; // promote to non-nullable for setState closure
        setState(() {
          _snappedBusLocation = snappedCoord;
          // ETA is now delivered server-side via eta_update WebSocket message.
          // We keep distance and route for the polyline overlay only.
          _distance = info['distance'];
          _routePoints = info['route'];
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
  /// Reconnect policy:
  ///  • Offline:       reconnect immediately.
  ///  • Connected but silent >45 s (zombie TCP):  reconnect.
  ///  • Connected and receiving messages:  do nothing — the server will push
  ///    trip_started automatically when a trip begins.  Forcing periodic
  ///    reconnects when has_active_trip==false causes an infinite
  ///    connect→trip_state(false)→reconnect loop.
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
        return;
      }

      // Connected — check for zombie (server alive but no messages delivered).
      // A healthy connection always delivers trip_state on connect, so 45 s
      // of silence means the TCP socket is dead without a clean close.
      final silence = _lastWsMessageAt == null
          ? const Duration(days: 1)
          : DateTime.now().difference(_lastWsMessageAt!);
      if (silence.inSeconds > 45) {
        debugPrint(
          '[TripWatcher] Zombie detected (${silence.inSeconds}s silent) — reconnecting bus $busId');
        _webSocketService.disconnect();
        _webSocketService.subscribeToBus(busId);
      }
      // Otherwise: connected and alive — wait for server-pushed trip_started.
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

  String _getEtaLabel() {
    if (_etaMinutes == null) return '';
    if (_etaMinutes! <= 1) return '1 min away';
    return '$_etaMinutes mins away';
  }

  /// En route layout: driver card + actions + route progress
  Widget _buildEnRouteInfo(ColorScheme colorScheme, bool isDark) {
    final String routeName = _getRouteDisplay();
    final String driverName = _childData?['driverName']?.toString() ?? 'Driver';
    const kNavy = Color(0xFF0B1C30);
    const kYellow = Color(0xFFFED01B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Driver card + action buttons row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dark driver card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Driver initial avatar with yellow dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _getDriverInitial(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: kYellow,
                                shape: BoxShape.circle,
                                border: Border.all(color: kNavy, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'VERIFIED DRIVER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Call button
              GestureDetector(
                onTap: () => _makePhoneCall('+254718073907'),
                child: Container(
                  width: 56,
                  decoration: BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.phone_rounded, color: kYellow, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Route chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.route_rounded,
                  size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                routeName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_etaMinutes != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$_etaMinutes min',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// At rest layout (home, school, etc.)
  Widget _buildAtRestInfo(ColorScheme colorScheme, bool isDark) {
    final status = (_childData?['status'] ?? '').toString().toLowerCase();
    final childName = _childData?['name'] ?? 'Child';
    final firstName = childName.toString().split(' ').first;

    final bool isAtSchool = status == 'at_school' || status == 'at-school';
    final IconData icon = isAtSchool ? Icons.school_rounded : Icons.home_rounded;
    final Color accentColor =
        isAtSchool ? const Color(0xFF004AC6) : const Color(0xFF006242);
    final String message = isAtSchool
        ? '$firstName is safely at school'
        : '$firstName is safely at home';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _getRouteDisplay(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _makePhoneCall('+254718073907'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_rounded, size: 20, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const kNavy = Color(0xFF0B1C30);
    const kYellow = Color(0xFFFED01B);

    if (_childData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No child data available')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen map ───────────────────────────────────────────────
          Positioned.fill(
            child: _isLoadingLocation
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
                            const SizedBox(height: 16),
                            Text('Unable to get location',
                                style: theme.textTheme.titleLarge),
                          ],
                        ),
                      ),
          ),

          // ── Floating top bar ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button — always dark icon on white bg
                  _MapButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: kNavy, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── Right-side map controls ───────────────────────────────────────
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.34,
            child: Column(
              children: [
                _MapButton(
                  onTap: () {
                    final target = _busLocation != null
                        ? ll.LatLng(
                            _busLocation!.latitude, _busLocation!.longitude)
                        : _homeLocation;
                    if (target != null) {
                      _mapboxMap?.flyTo(
                        CameraOptions(
                            center: latLngToPoint(target), zoom: 16.0),
                        MapAnimationOptions(duration: 800),
                      );
                    }
                  },
                  child: Icon(Icons.my_location_rounded,
                      color: colorScheme.primary, size: 22),
                ),
              ],
            ),
          ),

          // ── Bottom draggable sheet ────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.20,
            maxChildSize: 0.65,
            snap: true,
            snapSizes: const [0.32, 0.65],
            builder: (context, scrollController) {
              final bool isEnRoute = _isChildEnRoute();
              final sheetBg = isDark
                  ? const Color(0xFF1C1C1E)
                  : Colors.white;

              return Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Status pill + ETA | Plate chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kNavy,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      isEnRoute ? 'ON BUS' : 'AT REST',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: kYellow,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  if (_etaMinutes != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      _getEtaLabel(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getTripStatus(),
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // License plate chip
                        if (_childData?['busNumber'] != null &&
                            _childData!['busNumber'] != 'N/A') ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'LICENSE PLATE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _childData!['busNumber'].toString(),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Dynamic content
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

// ─── Shared map overlay widgets ───────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _MapButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

