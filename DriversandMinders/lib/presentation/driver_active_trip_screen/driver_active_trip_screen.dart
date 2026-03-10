import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart' show Dio, DioException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/gps_stream_service.dart';
import '../../services/native_location_service.dart';
import '../../services/trip_state_service.dart';
import '../../widgets/driver_drawer_widget.dart';

class DriverActiveTripScreen extends StatefulWidget {
  const DriverActiveTripScreen({super.key});

  @override
  State<DriverActiveTripScreen> createState() => _DriverActiveTripScreenState();
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen>
    implements OnPointAnnotationClickListener {
  // ── Services ────────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();
  final NativeLocationService _nativeLocationService = NativeLocationService();
  final TripStateService _tripStateService = TripStateService();

  // ── Trip state ───────────────────────────────────────────────────────────────
  DateTime _tripStartTime = DateTime.now();
  String _elapsedTime = "00:00:00";
  bool _isLoadingData = true;
  String? _errorMessage;
  int? _currentTripId;
  Timer? _locationUpdateTimer;

  Map<String, dynamic> _tripData = {};
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _busData;
  String _driverName = '';

  // ── Mapbox map ───────────────────────────────────────────────────────────────
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineAnnotationManager;
  PointAnnotationManager? _homeAnnotationManager;
  PointAnnotationManager? _navAnnotationManager;

  // Rendered PNG bitmaps
  Map<String, Uint8List> _homeMarkerImages = {};
  Uint8List? _navArrowImage;

  // Driver GPS — position comes from the shared singleton, not a new stream.
  geo.Position? _driverPosition;
  StreamSubscription<geo.Position>? _gpsListener; // local listener only
  final GpsStreamService _gps = GpsStreamService();
  PointAnnotation? _navAnnotation;
  PolylineAnnotation? _routePolyline;

  // Route + ETA
  final Map<String, Duration?> _studentEtas = {};
  DateTime? _lastRouteRefresh;

  // Next-turn navigation instruction (from Mapbox Directions steps)
  String? _nextTurnInstruction;
  String? _nextTurnModifier; // 'left', 'right', 'straight', 'slight left', etc.
  String? _nextTurnType; // 'turn', 'arrive', 'continue', 'roundabout', etc.
  double _nextTurnDistanceM = 0;

  // Tap → student lookup
  final Map<String, Map<String, dynamic>> _annotationToStudent = {};
  Map<String, dynamic>? _selectedStudent;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // ── Computed helpers ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _mappableStudents => _students.where((s) {
        final lat = s['lat'] as double?;
        final lng = s['lng'] as double?;
        // Exclude null and (0,0) — the latter is a DB default that was never
        // set. Including (0,0) creates a ~4,500 km detour to the Gulf of Guinea
        // which exceeds the Mapbox Directions distance limit.
        return lat != null && lng != null && (lat != 0.0 || lng != 0.0);
      }).toList();

  int get _studentsPickedUp =>
      _students.where((s) => s["isPickedUp"] as bool? ?? false).length;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _startElapsedTimeTimer();
    _renderMarkerImages();
    _initDriverLocation();
    _checkForActiveTripAndLoad();
  }

  @override
  void dispose() {
    _gpsListener?.cancel(); // cancel this screen's listener only
    _sheetController.dispose();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Marker image rendering
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _renderMarkerImages() async {
    final home = await _renderPinIcon(icon: Icons.home_rounded);
    final onBus = await _renderPinIcon(
      icon: Icons.directions_bus,
      pinColor: const Color(0xFF3B82F6),
    );
    final atSchool = await _renderPinIcon(
      icon: Icons.school,
      pinColor: const Color(0xFF10B981),
    );
    final navArrow = await _renderNavigationArrow();

    if (!mounted) return;
    setState(() {
      _homeMarkerImages = {
        'home': home,
        'on_bus': onBus,
        'at_school': atSchool,
      };
      _navArrowImage = navArrow;
    });

    await _placeHomeMarkers();
    await _updateNavAnnotation();
  }

  Future<Uint8List> _renderPinIcon({
    required IconData icon,
    Color pinColor = const Color(0xFF2563EB),
    Color iconColor = Colors.white,
  }) async {
    const double w = 96.0, h = 124.0, r = 40.0;
    const double cx = w / 2, cy = r + 6;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    canvas.drawCircle(Offset(cx, cy), r + 3, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = pinColor);
    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.44, cy + r * 0.62)
        ..quadraticBezierTo(cx - 5, h - 22, cx, h - 3)
        ..quadraticBezierTo(cx + 5, h - 22, cx + r * 0.44, cy + r * 0.62)
        ..close(),
      Paint()..color = pinColor,
    );

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

  /// Google Maps-style navigation arrow:
  /// Blue circle with accuracy pulse ring and white directional chevron inside.
  /// Points "up" (north) at heading=0 — Mapbox rotates it with iconRotate.
  Future<Uint8List> _renderNavigationArrow() async {
    const double size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final double cx = size / 2;
    final double cy = size / 2;

    // Accuracy pulse ring
    canvas.drawCircle(
      Offset(cx, cy),
      size / 2,
      Paint()..color = const Color(0xFF4285F4).withValues(alpha: 0.18),
    );

    // White border circle
    canvas.drawCircle(
      Offset(cx, cy),
      24,
      Paint()..color = Colors.white,
    );

    // Blue filled circle
    canvas.drawCircle(
      Offset(cx, cy),
      20,
      Paint()..color = const Color(0xFF4285F4),
    );

    // White navigation chevron pointing up (direction of travel)
    final path = Path()
      ..moveTo(cx, cy - 13) // tip (north/forward)
      ..lineTo(cx + 10, cy + 9) // bottom-right wing
      ..lineTo(cx, cy + 4) // concave base center
      ..lineTo(cx - 10, cy + 9) // bottom-left wing
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Driver GPS
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _initDriverLocation() async {
    // Subscribe to the shared GpsStreamService instead of opening a new
    // Geolocator stream.  The singleton is already running from the home
    // screen, so we get a fix instantly — no "Acquiring GPS..." delay.
    try {
      _gpsListener?.cancel();
      _locationUpdateTimer?.cancel();

      // Ensure the stream is running (guard for edge-case where user arrives
      // at active trip without passing through home screen first).
      _gps.ensureStarted();

      // Snap to the last known fix immediately — zero wait if home screen
      // already acquired a position.
      final snap = _gps.lastKnownPosition;
      if (snap != null && mounted) {
        setState(() => _driverPosition = snap);
        await _updateNavAnnotation();
        _updateRoute();
        if (_mapboxMap != null) {
          _mapboxMap!.setCamera(CameraOptions(
            center: _latlng(snap.latitude, snap.longitude),
            bearing: snap.heading,
            pitch: 50.0,
            zoom: 16.5,
          ));
        }
      }

      // Subscribe to the shared broadcast for live navigation updates.
      _gpsListener = _gps.stream.listen((geo.Position pos) {
        if (!mounted) return;
        setState(() => _driverPosition = pos);
        _updateNavAnnotation();
        _updateRoute(); // throttled internally to once per 45 s

        if (_mapboxMap != null) {
          _mapboxMap!.setCamera(CameraOptions(
            center: _latlng(pos.latitude, pos.longitude),
            bearing: pos.heading,
            pitch: 50.0,
            zoom: 16.5,
          ));
        }
      });
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Mapbox map callbacks
  // ══════════════════════════════════════════════════════════════════════════════

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Apply navigation-style tilt immediately so the map is never flat,
    // even before the first GPS position arrives.
    await mapboxMap.setCamera(CameraOptions(pitch: 50.0, zoom: 16.0));

    // Polyline layer first so it renders below the point markers
    _polylineAnnotationManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();
    _homeAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _navAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    _homeAnnotationManager!.addOnPointAnnotationClickListener(this);

    await _placeHomeMarkers();
    await _updateNavAnnotation();
    _centerMapInitially();
    _updateRoute();
  }

  void _centerMapInitially() {
    if (_mapboxMap == null) return;
    Point? center;
    if (_driverPosition != null) {
      center = _latlng(_driverPosition!.latitude, _driverPosition!.longitude);
    } else if (_mappableStudents.isNotEmpty) {
      center = _latlng(
        _mappableStudents.first['lat'] as double,
        _mappableStudents.first['lng'] as double,
      );
    }
    if (center != null) {
      _mapboxMap!.flyTo(
        CameraOptions(center: center, zoom: 16.0, pitch: 50.0),
        MapAnimationOptions(duration: 800),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Annotation helpers
  // ══════════════════════════════════════════════════════════════════════════════

  Point _latlng(double lat, double lng) =>
      Point(coordinates: Position(lng, lat));

  Future<void> _placeHomeMarkers() async {
    if (_homeAnnotationManager == null || _homeMarkerImages.isEmpty) return;
    _annotationToStudent.clear();
    await _homeAnnotationManager!.deleteAll();

    for (final student in _mappableStudents) {
      final lat = student['lat'] as double;
      final lng = student['lng'] as double;
      final isPickedUp = student['isPickedUp'] as bool? ?? false;
      final locationStatus =
          (student['locationStatus'] as String? ?? 'home').toLowerCase();

      String imageKey;
      if (isPickedUp ||
          locationStatus == 'on-bus' ||
          locationStatus == 'on_bus') {
        imageKey = 'on_bus';
      } else if (locationStatus == 'at-school' ||
          locationStatus == 'at_school') {
        imageKey = 'at_school';
      } else {
        imageKey = 'home';
      }

      final image = _homeMarkerImages[imageKey] ?? _homeMarkerImages['home']!;
      final isSelected = _selectedStudent?['id'] == student['id'];

      final annotation = await _homeAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: _latlng(lat, lng),
          image: image,
          iconSize: isSelected ? 1.2 : 0.85,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
      _annotationToStudent[annotation.id] = student;
    }
  }

  Future<void> _updateNavAnnotation() async {
    if (_navAnnotationManager == null ||
        _navArrowImage == null ||
        _driverPosition == null) return;

    final point =
        _latlng(_driverPosition!.latitude, _driverPosition!.longitude);

    if (_navAnnotation != null) {
      _navAnnotation!.geometry = point;
      _navAnnotation!.iconRotate = _driverPosition!.heading;
      await _navAnnotationManager!.update(_navAnnotation!);
    } else {
      _navAnnotation = await _navAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: point,
          image: _navArrowImage,
          iconSize: 0.95,
          iconAnchor: IconAnchor.CENTER,
          iconRotate: _driverPosition!.heading,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // OnPointAnnotationClickListener
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final student = _annotationToStudent[annotation.id];
    if (student == null) return false;
    _onStudentSelected(student);
    return true;
  }

  void _onStudentSelected(Map<String, dynamic> student) {
    // Highlight the student in the sheet without moving the camera away from
    // the driver — the map always stays centred on the driver.
    setState(() {
      _selectedStudent = student;
    });
    _placeHomeMarkers();
    _sheetController.animateTo(
      0.38,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _recenterOnDriver() {
    if (_driverPosition == null || _mapboxMap == null) return;
    setState(() => _selectedStudent = null);
    _mapboxMap!.flyTo(
      CameraOptions(
        center: _latlng(_driverPosition!.latitude, _driverPosition!.longitude),
        zoom: 16.5,
        bearing: _driverPosition!.heading,
        pitch: 50.0,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Trip business logic (unchanged)
  // ══════════════════════════════════════════════════════════════════════════════

  Future<void> _checkForActiveTripAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripInProgress = prefs.getBool('trip_in_progress') ?? false;
      final currentTripId = prefs.getInt('current_trip_id');

      if (!tripInProgress || currentTripId == null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('No active trip found. Please start a trip first.'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                behavior: SnackBarBehavior.fixed,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver-start-shift-screen',
              (route) => false,
            );
          });
        }
        return;
      }

      try {
        final backendTrip = await _apiService.getActiveTrip();
        if (backendTrip == null || backendTrip['status'] != 'in-progress') {
          await _clearTripStateLocally();
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Trip has already ended. Returning to start shift.'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  behavior: SnackBarBehavior.fixed,
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/driver-start-shift-screen',
                (route) => false,
              );
            });
          }
          return;
        }
        await _loadTripData(activeTrip: backendTrip);
        await _initializeLocationTracking();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cannot verify trip status with server. Using local data.'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              behavior: SnackBarBehavior.fixed,
              duration: Duration(seconds: 3),
            ),
          );
        }
        await _loadTripData();
        await _initializeLocationTracking();
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading trip. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.fixed,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/driver-start-shift-screen',
            (route) => false,
          );
        });
      }
    }
  }

  Future<void> _initializeLocationTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final busId = prefs.getInt('current_bus_id');
      final apiUrl = ApiConfig.apiBaseUrl;

      if (token == null || busId == null) return;

      await _tripStateService.saveTripState(
        tripId: _currentTripId ?? DateTime.now().millisecondsSinceEpoch,
        tripType: 'active',
        startTime: _tripStartTime,
        busId: busId,
        busNumber: _busData?['bus_number'] ?? 'BUS-$busId',
      );

      await _nativeLocationService.startLocationTracking(
        token: token,
        busId: busId,
        apiUrl: apiUrl,
      );
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> _loadTripData({Map<String, dynamic>? activeTrip}) async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentTripId = prefs.getInt('current_trip_id');
      final tripStartTimeStr = prefs.getString('trip_start_time');
      if (tripStartTimeStr != null) {
        _tripStartTime = DateTime.parse(tripStartTimeStr);
      }

      final userName = (prefs.getString('user_name')?.isNotEmpty == true
              ? prefs.getString('user_name')
              : prefs.getString('driver_name')) ??
          '';
      if (userName.isNotEmpty) setState(() => _driverName = userName);
      final busResponse = await _apiService.getDriverBus();
      final routeResponse = await _apiService.getDriverRoute();

      _busData = busResponse['buses'] is Map
          ? busResponse['buses'] as Map<String, dynamic>
          : (busResponse['buses'] is List &&
                  (busResponse['buses'] as List).isNotEmpty
              ? busResponse['buses'][0] as Map<String, dynamic>
              : null);

      final tripType = prefs.getString('current_trip_type') ?? 'pickup';

      _tripData = {
        "tripId":
            "TRP_${DateTime.now().toString().substring(0, 10).replaceAll('-', '')}_${_busData?['id'] ?? '001'}",
        "trip_type": tripType,
        "routeNumber": routeResponse['route_name']?.toString() ?? "N/A",
        "routeName": routeResponse['route_name'] ?? 'No Route',
        "driverName": userName,
        "busNumber": _busData?['bus_number'] ?? 'N/A',
        "startTime":
            "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        "estimatedEndTime": 'N/A',
        "totalDistance": routeResponse['total_distance']?.toString() ?? 'N/A',
        "stops": [],
      };

      if (routeResponse['children'] != null &&
          routeResponse['children'] is List) {
        final Map<String, Map<String, dynamic>> byId = {};
        for (var child in routeResponse['children']) {
          final String id = child['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          String gradeValue = child['grade']?.toString() ??
              child['class_grade']?.toString() ??
              'N/A';
          if (gradeValue.toLowerCase().startsWith('grade')) {
            gradeValue = gradeValue.substring(5).trim();
          }
          byId[id] = {
            "id": id,
            "name": '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
            "grade": gradeValue,
            "stopName": child['address']?.toString() ?? 'No address',
            "parentContact": child['emergency_contact']?.toString() ??
                child['parent_contact']?.toString() ??
                'N/A',
            "specialNotes": child['special_needs']?.toString() ?? '',
            "isPickedUp": false,
            "lat": double.tryParse(child['home_latitude']?.toString() ?? ''),
            "lng": double.tryParse(child['home_longitude']?.toString() ?? ''),
          };
        }
        _students = byId.values.toList();
      }

      // -----------------------------------------------------------------------
      // Populate route stops from the active trip (ordered by `order` field).
      // This drives the map polyline and ensures students appear in pickup order.
      // -----------------------------------------------------------------------
      final tripData = activeTrip ?? await _apiService.getActiveTrip();
      if (tripData != null) {
        if (tripData['id'] != null) {
          _currentTripId ??= tripData['id'] as int?;
        }

        final rawStops =
            (tripData['stops'] as List? ?? []).cast<Map<String, dynamic>>();

        // Stops arrive pre-sorted from the server but we sort again as a safety net.
        rawStops.sort((a, b) =>
            (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

        // Convert TripSerializer stop format → map annotation format
        _tripData["stops"] = rawStops.map((stop) {
          final loc = stop['location'] as Map<String, dynamic>?;
          return {
            "latitude": (loc?['latitude'] as num?)?.toDouble() ?? 0.0,
            "longitude": (loc?['longitude'] as num?)?.toDouble() ?? 0.0,
            "name": stop['address'] ?? 'Stop',
            "order": stop['order'] ?? 0,
            "isCompleted": stop['status'] == 'completed',
          };
        }).toList();

        // Build child_id → stop order map so the student list matches pickup sequence.
        // Django REST Framework serializes field names as snake_case, so try both
        // children_ids (snake) and childrenIds (camel) for compatibility.
        final Map<int, int> childStopOrder = {};
        for (final stop in rawStops) {
          final stopOrder = stop['order'] as int? ?? 999;
          final ids = (stop['children_ids'] as List? ??
                  stop['childrenIds'] as List? ??
                  [])
              .cast<int>();
          for (final childId in ids) {
            childStopOrder[childId] = stopOrder;
          }
        }

        if (childStopOrder.isNotEmpty) {
          // Sort by backend stop order — this is the authoritative pickup sequence.
          _students.sort((a, b) {
            final aId = int.tryParse(a['id'].toString()) ?? 0;
            final bId = int.tryParse(b['id'].toString()) ?? 0;
            return (childStopOrder[aId] ?? 999)
                .compareTo(childStopOrder[bId] ?? 999);
          });
        } else {
          // Fallback: sort by distance from the school, which is represented by
          // the last stop in the route (highest order value on a pickup trip).
          // Pickup = farthest from school first; Dropoff = nearest first.
          final tripType = _tripData['trip_type'] as String? ?? 'pickup';
          final stops = _tripData['stops'] as List?;
          if (stops != null && stops.isNotEmpty) {
            final sortedStops = List<Map<String, dynamic>>.from(
                stops.cast<Map<String, dynamic>>())
              ..sort((a, b) =>
                  (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
            final schoolStop = sortedStops.last;
            final schoolLat = schoolStop['latitude'] as double?;
            final schoolLng = schoolStop['longitude'] as double?;

            if (schoolLat != null &&
                schoolLng != null &&
                schoolLat != 0.0 &&
                schoolLng != 0.0) {
              _students.sort((a, b) {
                final aLat = a['lat'] as double?;
                final aLng = a['lng'] as double?;
                final bLat = b['lat'] as double?;
                final bLng = b['lng'] as double?;
                if (aLat == null || aLng == null) return 1;
                if (bLat == null || bLng == null) return -1;
                final aDist = geo.Geolocator.distanceBetween(
                    aLat, aLng, schoolLat, schoolLng);
                final bDist = geo.Geolocator.distanceBetween(
                    bLat, bLng, schoolLat, schoolLng);
                // Pickup: farthest first (desc). Dropoff: nearest first (asc).
                return tripType == 'dropoff'
                    ? aDist.compareTo(bDist)
                    : bDist.compareTo(aDist);
              });
            }
          }
        }
      }

      setState(() => _isLoadingData = false);

      // Refresh map markers and route after data load.
      // Reset throttle so the route is fetched immediately with real student data.
      _lastRouteRefresh = null;
      await _placeHomeMarkers();
      _updateRoute();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load trip data: ${e.toString()}';
        _isLoadingData = false;
        _tripData = {
          "tripId": "N/A",
          "routeNumber": "N/A",
          "routeName": "No Route",
          "driverName": _driverName,
          "busNumber": "N/A",
          "startTime":
              "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          "estimatedEndTime": "N/A",
          "totalDistance": "N/A",
          "stops": [],
        };
        _students = [];
      });
    }
  }

  void _startElapsedTimeTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_tripStartTime);
      final h = elapsed.inHours.toString().padLeft(2, '0');
      final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
      final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      setState(() => _elapsedTime = '$h:$m:$s');
      _startElapsedTimeTimer();
    });
  }

  Future<void> _onPickupStatusChanged(String studentId, bool isPickedUp) async {
    final student = _students.firstWhere(
      (s) => s['id'].toString() == studentId,
      orElse: () => {},
    );
    if (student.isEmpty) return;

    setState(() => student["isPickedUp"] = isPickedUp);
    _placeHomeMarkers();
    // Force a fresh route calculation excluding the now-handled student
    _lastRouteRefresh = null;
    _updateRoute();

    try {
      final prefs = await SharedPreferences.getInstance();
      final tripType = prefs.getString('current_trip_type') ?? 'pickup';
      await _apiService.markAttendance(
        childId: int.parse(studentId),
        status: isPickedUp ? 'picked_up' : 'pending',
        tripType: tripType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  isPickedUp
                      ? '${student["name"]} marked as picked up'
                      : '${student["name"]} marked as not picked up',
                ),
              ),
            ]),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 2.w),
              Expanded(child: Text('Saved locally. Will sync when online.')),
            ]),
            duration: Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  void _onEndTripPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Trip'),
        content: Text(
            'Are you sure you want to end this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endTrip();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
  }

  Future<void> _endTrip() async {
    HapticFeedback.mediumImpact();

    if (_currentTripId == null) {
      await _clearTripStateLocally();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/driver-start-shift-screen',
          (route) => false,
        );
      }
      return;
    }

    final totalStudents = _students.length;
    final studentsCompleted =
        _students.where((s) => s["isPickedUp"] as bool? ?? false).length;
    final studentsAbsent = totalStudents - studentsCompleted;

    try {
      await _apiService.endTrip(
        tripId: _currentTripId!,
        totalStudents: totalStudents,
        studentsCompleted: studentsCompleted,
        studentsAbsent: studentsAbsent,
        studentsPending: 0,
      );
      await _clearTripStateLocally();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip ended successfully'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.fixed,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/driver-start-shift-screen',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final shouldForceEnd = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(children: [
              Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
              SizedBox(width: 2.w),
              Expanded(child: Text('Failed to End Trip')),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not connect to server to end trip.'),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary),
                  ),
                  child: Text(
                    '• Try Again: Attempt to end trip again\n• Force End Locally: Stop timer and location tracking',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Try Again'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary),
                child: Text('Force End Locally'),
              ),
            ],
          ),
        );

        if (shouldForceEnd == true) {
          await _clearTripStateLocally();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Trip ended locally. Location tracking stopped.'),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                behavior: SnackBarBehavior.fixed,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver-start-shift-screen',
              (route) => false,
            );
          }
        }
      }
    }
  }

  Future<void> _clearTripStateLocally() async {
    try {
      await _nativeLocationService.stopLocationTracking();
    } catch (_) {}
    _locationUpdateTimer?.cancel();
    try {
      await _tripStateService.clearTripState();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_trip_id');
      await prefs.remove('current_trip_type');
      await prefs.remove('trip_start_time');
      await prefs.setBool('trip_in_progress', false);
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Route + ETA via Mapbox Directions API
  // ══════════════════════════════════════════════════════════════════════════════

  static String _formatEta(Duration d) {
    if (d.inSeconds < 60) return '< 1 min';
    if (d.inHours < 1) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  /// Sorts [pending] in-place for the correct driving order based on trip type.
  ///
  ///   - Pickup:  farthest-from-school first → nearest last.
  ///              Reference = last stop (highest order ≈ school destination).
  ///              Sort descending by distance from reference.
  ///   - Dropoff: nearest-to-school first   → farthest last.
  ///              Reference = first stop (lowest order ≈ closest stop to school).
  ///              Sort ascending by distance from reference.
  ///
  /// Falls back to the existing load-time sort order if no valid reference stop
  /// can be resolved.
  void _sortPendingForRoute(List<Map<String, dynamic>> pending) {
    final tripType = _tripData['trip_type'] as String? ?? 'pickup';

    // Resolve the geographic reference point used for distance-based ordering.
    //
    // Priority 1 — trip stops (most accurate, server-authoritative):
    //   Pickup:  last stop (highest order) ≈ school destination.
    //   Dropoff: first stop (lowest order) ≈ stop nearest the school.
    //
    // Priority 2 — driver's current position (fallback when stops are absent
    //   or have unset coordinates).  Valid at trip start when driver is still
    //   at the school/depot; good enough for the initial polyline draw.
    double? refLat;
    double? refLng;

    final rawStops = _tripData['stops'] as List?;
    if (rawStops != null && rawStops.isNotEmpty) {
      final stops = rawStops.cast<Map<String, dynamic>>().toList()
        ..sort(
            (a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
      final refStop = tripType == 'dropoff' ? stops.first : stops.last;
      final lat = refStop['latitude'] as double?;
      final lng = refStop['longitude'] as double?;
      if (lat != null && lng != null && !(lat == 0.0 && lng == 0.0)) {
        refLat = lat;
        refLng = lng;
      }
    }

    // Fallback to driver position (school proxy at trip start).
    if (refLat == null && _driverPosition != null) {
      refLat = _driverPosition!.latitude;
      refLng = _driverPosition!.longitude;
    }

    if (refLat == null || refLng == null) return;

    final anchorLat = refLat;
    final anchorLng = refLng;

    pending.sort((a, b) {
      final aLat = a['lat'] as double? ?? 0.0;
      final aLng = a['lng'] as double? ?? 0.0;
      final bLat = b['lat'] as double? ?? 0.0;
      final bLng = b['lng'] as double? ?? 0.0;
      final aDist =
          geo.Geolocator.distanceBetween(aLat, aLng, anchorLat, anchorLng);
      final bDist =
          geo.Geolocator.distanceBetween(bLat, bLng, anchorLat, anchorLng);
      // Pickup:  descending — farthest from school/anchor first.
      // Dropoff: ascending  — nearest to school/anchor first.
      return tripType == 'dropoff'
          ? aDist.compareTo(bDist)
          : bDist.compareTo(aDist);
    });
  }

  Future<void> _updateRoute() async {
    if (_driverPosition == null || _polylineAnnotationManager == null) return;

    // Throttle: at most once every 45 seconds.
    // Only stamp _lastRouteRefresh when we actually hit the Directions API so
    // early returns (no GPS, no manager, or empty student list) do NOT eat up
    // the 45-second window.
    final now = DateTime.now();
    if (_lastRouteRefresh != null &&
        now.difference(_lastRouteRefresh!) < const Duration(seconds: 45))
      return;

    final pending = _mappableStudents
        .where((s) => !(s['isPickedUp'] as bool? ?? false))
        .toList();

    if (pending.isEmpty) {
      if (_routePolyline != null) {
        try {
          await _polylineAnnotationManager!.delete(_routePolyline!);
        } catch (_) {}
        _routePolyline = null;
      }
      if (mounted) setState(() => _studentEtas.clear());
      return;
    }

    // Stamp throttle only now — we are about to call the Directions API.
    _lastRouteRefresh = now;

    // Sort waypoints for the correct trip-type driving order:
    //   Pickup  → farthest-from-school first, nearest last (driver collects
    //             far students and converges toward school).
    //   Dropoff → nearest-to-school first, farthest last (driver drops nearby
    //             students before heading out further).
    _sortPendingForRoute(pending);

    // Mapbox Directions API allows 25 waypoints total (driver position = 1).
    // Cap student stops at 23 to leave one slot of headroom and keep response
    // sizes bounded while still giving ETAs to all students on typical routes.
    final capped = pending.length > 23 ? pending.sublist(0, 23) : pending;

    final waypoints = [
      '${_driverPosition!.longitude},${_driverPosition!.latitude}',
      ...capped.map((s) => '${s['lng']},${s['lat']}'),
    ].join(';');

    print('🗺️ _updateRoute: fetching route for ${capped.length} stops');

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.mapbox.com/directions/v5/mapbox/driving/$waypoints',
        queryParameters: {
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'true',
          'access_token': ApiConfig.mapboxAccessToken,
        },
      ).timeout(const Duration(seconds: 25));

      print('🗺️ _updateRoute: HTTP ${response.statusCode}');

      final routes = response.data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        print('🗺️ _updateRoute: no routes returned');
        return;
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final rawCoords = geometry['coordinates'] as List;
      final coords = rawCoords
          .map((c) => Position(
                (c as List)[0].toDouble(),
                c[1].toDouble(),
              ))
          .toList();

      // Draw / update polyline
      if (_routePolyline != null) {
        _routePolyline!.geometry = LineString(coordinates: coords);
        await _polylineAnnotationManager!.update(_routePolyline!);
      } else {
        _routePolyline = await _polylineAnnotationManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: coords),
            lineColor: const Color(0xFF4285F4).value,
            lineWidth: 4.5,
            lineOpacity: 0.82,
          ),
        );
      }

      // Cumulative ETA per pending student from leg durations
      final legs = route['legs'] as List;
      double cumSecs = 0;
      final newEtas = <String, Duration?>{};
      for (int i = 0; i < capped.length && i < legs.length; i++) {
        cumSecs += (legs[i]['duration'] as num).toDouble();
        newEtas[capped[i]['id'] as String] = Duration(seconds: cumSecs.round());
      }

      // Parse the next turn instruction from the first step of the first leg.
      // The first step is the driver's immediate next maneuver.
      String? nextInstruction;
      String? nextModifier;
      String? nextType;
      double nextDistM = 0;
      if (legs.isNotEmpty) {
        final firstLeg = legs[0] as Map<String, dynamic>;
        final steps = firstLeg['steps'] as List?;
        if (steps != null && steps.isNotEmpty) {
          // Step 0 is always a departure maneuver ("Head north…"). If a real
          // turn exists as step 1, prefer it; otherwise fall back to step 0.
          final stepIdx = steps.length > 1 ? 1 : 0;
          final step = steps[stepIdx] as Map<String, dynamic>;
          final maneuver = step['maneuver'] as Map<String, dynamic>?;
          nextInstruction = maneuver?['instruction'] as String?;
          nextType = maneuver?['type'] as String?;
          nextModifier = maneuver?['modifier'] as String?;
          nextDistM = (step['distance'] as num?)?.toDouble() ?? 0.0;
        }
      }

      if (mounted) {
        setState(() {
          _studentEtas
            ..clear()
            ..addAll(newEtas);
          _nextTurnInstruction = nextInstruction;
          _nextTurnType = nextType;
          _nextTurnModifier = nextModifier;
          _nextTurnDistanceM = nextDistM;
        });
      }
      print('✅ _updateRoute: polyline drawn, ${newEtas.length} ETAs set');
    } on DioException catch (e) {
      print(
          '❌ _updateRoute DioException: ${e.message} | ${e.response?.statusCode} | ${e.response?.data}');
      // Network unavailable — keep existing route/ETAs
      _lastRouteRefresh = null; // allow retry next call
    } catch (e) {
      print('❌ _updateRoute error: $e');
      _lastRouteRefresh = null; // allow retry next call
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Navigation turn helpers
  // ══════════════════════════════════════════════════════════════════════════════

  /// Returns an icon appropriate for the Mapbox maneuver type + modifier.
  IconData _turnIcon(String? type, String? modifier) {
    final mod = modifier?.toLowerCase() ?? '';
    final tp = type?.toLowerCase() ?? '';

    if (tp == 'arrive') return Icons.location_on;
    if (tp == 'roundabout' || tp == 'rotary') return Icons.roundabout_left;
    if (tp == 'fork') {
      if (mod.contains('right')) return Icons.fork_right;
      return Icons.fork_left;
    }
    if (tp == 'merge') return Icons.merge;
    if (mod.contains('uturn')) return Icons.u_turn_left;

    if (mod.contains('sharp right')) return Icons.turn_sharp_right;
    if (mod.contains('sharp left')) return Icons.turn_sharp_left;
    if (mod.contains('slight right')) return Icons.turn_slight_right;
    if (mod.contains('slight left')) return Icons.turn_slight_left;
    if (mod.contains('right')) return Icons.turn_right;
    if (mod.contains('left')) return Icons.turn_left;
    return Icons.straight;
  }

  String _formatTurnDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4285F4)),
              SizedBox(height: 16),
              Text('Loading trip…',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: DriverDrawerWidget(
        currentRoute: '/driver-active-trip-screen',
        driverData: {
          'name': _driverName.isNotEmpty ? _driverName : (_tripData['driverName'] ?? ''),
          'bus_number':
              _busData?['bus_number'] ?? _busData?['number_plate'] ?? 'N/A',
        },
        hasActiveTrip: true,
      ),
      body: Stack(
        children: [
          // ── Full-screen Mapbox map ─────────────────────────────────────────
          MapWidget(
            styleUri: 'mapbox://styles/${ApiConfig.mapboxStyleId}',
            cameraOptions: CameraOptions(
              center: _driverPosition != null
                  ? _latlng(
                      _driverPosition!.latitude, _driverPosition!.longitude)
                  : _latlng(0.3476, 32.5825),
              zoom: 16.0,
              pitch: 50.0,
            ),
            onMapCreated: _onMapCreated,
            // No scroll listener: the map always follows the driver.
            // Camera is updated on every location poll in fetchOnce().
          ),

          // ── Trip timer badge (top-center) ──────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 72,
            right: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_tripData["trip_type"] == "pickup" ? "↑ Pickup" : "↓ Drop-off"}  •  $_studentsPickedUp/${_students.length}  •  $_elapsedTime',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // ── Menu button (top-left) ─────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 16,
            child: Builder(
              builder: (ctx) => _CircleButton(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: const Icon(Icons.menu, color: Colors.white, size: 22),
              ),
            ),
          ),

          // ── Recenter button (top-right) ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            right: 16,
            child: _CircleButton(
              onTap: _recenterOnDriver,
              child: Icon(
                Icons.my_location,
                color: _driverPosition != null
                    ? const Color(0xFF4285F4)
                    : Colors.white,
                size: 22,
              ),
            ),
          ),

          // Offline warning badge
          if (_errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Offline mode',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),

          // ── Next-turn instruction banner ───────────────────────────────────
          if (_nextTurnInstruction != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 68,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F).withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _turnIcon(_nextTurnType, _nextTurnModifier),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTurnDistance(_nextTurnDistanceM),
                            style: TextStyle(
                              color: const Color(0xFF93C5FD),
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _nextTurnInstruction!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Draggable bottom sheet ─────────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.32,
            minChildSize: 0.12,
            maxChildSize: 0.82,
            snap: true,
            snapSizes: const [0.32, 0.55, 0.82],
            builder: (context, scrollController) {
              return _TripBottomSheet(
                scrollController: scrollController,
                students: _students,
                selectedStudent: _selectedStudent,
                tripData: _tripData,
                totalPickedUp: _studentsPickedUp,
                mappableCount: _mappableStudents.length,
                studentEtas: _studentEtas,
                onStudentTap: _onStudentSelected,
                onPickupToggle: (id, val) => _onPickupStatusChanged(id, val),
                onEndTrip: _onEndTripPressed,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet ──────────────────────────────────────────────────────────────

class _TripBottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> students;
  final Map<String, dynamic>? selectedStudent;
  final Map<String, dynamic> tripData;
  final int totalPickedUp;
  final int mappableCount;
  final Map<String, Duration?> studentEtas;
  final ValueChanged<Map<String, dynamic>> onStudentTap;
  final Function(String id, bool) onPickupToggle;
  final VoidCallback onEndTrip;

  const _TripBottomSheet({
    required this.scrollController,
    required this.students,
    required this.selectedStudent,
    required this.tripData,
    required this.totalPickedUp,
    required this.mappableCount,
    required this.studentEtas,
    required this.onStudentTap,
    required this.onPickupToggle,
    required this.onEndTrip,
  });

  @override
  Widget build(BuildContext context) {
    final total = students.length;
    final remaining = total - totalPickedUp;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Trip stats row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.5.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBadge(
                    label: 'Total',
                    value: total.toString(),
                    color: const Color(0xFF4285F4)),
                _StatBadge(
                    label: 'Done',
                    value: totalPickedUp.toString(),
                    color: const Color(0xFF10B981)),
                _StatBadge(
                    label: 'Left',
                    value: remaining.toString(),
                    color: const Color(0xFFF59E0B)),
              ],
            ),
          ),

          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child:
                Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          ),
          SizedBox(height: 1.h),

          // Student list header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Row(
              children: [
                Text(
                  'Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$mappableCount / ${students.length} mapped',
                    style: TextStyle(
                      color: const Color(0xFF93C5FD),
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 0.5.h),

          // Student tiles — sorted by ETA ascending so the next student to
          // visit is always at the top. Picked-up students (no ETA) sink to
          // the bottom naturally since their ETA value is treated as ∞.
          ...(() {
            final sorted = students.toList()
              ..sort((a, b) {
                final aEta = studentEtas[a['id'] as String?]?.inSeconds ??
                    999999;
                final bEta = studentEtas[b['id'] as String?]?.inSeconds ??
                    999999;
                return aEta.compareTo(bEta);
              });
            return sorted.map((student) {
              final id = student['id'] as String? ?? '';
              final eta = studentEtas[id];
              return _StudentTripTile(
                student: student,
                isSelected: selectedStudent?['id'] == student['id'],
                eta: eta,
                onTap: student['lat'] != null
                    ? () => onStudentTap(student)
                    : null,
                onToggle: (val) => onPickupToggle(id, val),
              );
            });
          })(),

          SizedBox(height: 2.h),

          // End Trip button
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 3.h),
            child: ElevatedButton.icon(
              onPressed: onEndTrip,
              icon: Icon(Icons.stop_circle_outlined),
              label: Text(
                'End Trip',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat badge ────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Student trip tile ─────────────────────────────────────────────────────────

class _StudentTripTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isSelected;
  final Duration? eta;
  final VoidCallback? onTap;
  final ValueChanged<bool> onToggle;

  const _StudentTripTile({
    required this.student,
    required this.isSelected,
    required this.onToggle,
    this.eta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String? ?? 'Unknown';
    final grade = student['grade'] as String? ?? '';
    final address = student['stopName'] as String? ?? '';
    final isPickedUp = student['isPickedUp'] as bool? ?? false;
    final hasCoordsSet = student['lat'] != null && student['lng'] != null;

    final Color statusColor =
        isPickedUp ? const Color(0xFF10B981) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.4.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4285F4).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4285F4).withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
            SizedBox(width: 3.w),

            // Name + address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.isNotEmpty)
                    Text(
                      'Grade $grade  •  $address',
                      style: TextStyle(color: Colors.white54, fontSize: 9.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // ETA badge (only for pending students with a calculated ETA)
            if (!isPickedUp && eta != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: EdgeInsets.only(right: 1.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _DriverActiveTripScreenState._formatEta(eta!),
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            // No-location indicator
            if (!hasCoordsSet) ...[
              const Icon(Icons.location_off, color: Colors.white24, size: 14),
              SizedBox(width: 1.w),
            ],

            // Pickup toggle
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: isPickedUp,
                onChanged: onToggle,
                activeColor: const Color(0xFF10B981),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circle overlay button ────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
