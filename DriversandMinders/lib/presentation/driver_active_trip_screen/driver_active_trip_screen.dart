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

  // ── Mapbox map ───────────────────────────────────────────────────────────────
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineAnnotationManager;
  PointAnnotationManager? _homeAnnotationManager;
  PointAnnotationManager? _navAnnotationManager;

  // Rendered PNG bitmaps
  Map<String, Uint8List> _homeMarkerImages = {};
  Uint8List? _navArrowImage;

  // Driver GPS
  geo.Position? _driverPosition;
  StreamSubscription<geo.Position>? _positionStream;
  PointAnnotation? _navAnnotation;
  PolylineAnnotation? _routePolyline;

  // Route + ETA
  final Map<String, Duration?> _studentEtas = {};
  DateTime? _lastRouteRefresh;

  // Camera follow mode — stops when user pans, resumes on recenter tap
  bool _followDriver = true;
  // Guard: true while WE are moving the camera programmatically so the
  // onScrollListener does not mistake our own camera moves as a user pan.
  bool _isProgrammaticMove = false;

  // Tap → student lookup
  final Map<String, Map<String, dynamic>> _annotationToStudent = {};
  Map<String, dynamic>? _selectedStudent;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // ── Computed helpers ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _mappableStudents =>
      _students.where((s) {
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
    _positionStream?.cancel();
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
    try {
      // Use backend as the single source of truth for driver/bus position.
      // NativeLocationService pushes updates to Django; this screen polls the
      // /api/buses/{bus_id}/current-location/ endpoint to drive the map.

      // Cancel any existing polling timer
      _locationUpdateTimer?.cancel();

      final prefs = await SharedPreferences.getInstance();
      final prefBusId = prefs.getInt('current_bus_id');
      final busId = (_busData != null ? _busData!['id'] as int? : null) ?? prefBusId;
      if (busId == null) return;

      // Helper to fetch and apply latest position
      Future<void> fetchOnce() async {
        try {
          final response = await _apiService.getBusCurrentLocation(busId);
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;

            final lat = (data['lat'] as num?)?.toDouble();
            final lng = (data['lng'] as num?)?.toDouble();
            if (lat == null || lng == null) return;

            final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
            final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
            final timestampStr = data['timestamp'] as String?;
            final timestamp = timestampStr != null
                ? DateTime.tryParse(timestampStr) ?? DateTime.now()
                : DateTime.now();

            final pos = geo.Position(
              latitude: lat,
              longitude: lng,
              accuracy: 0.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: heading,
              headingAccuracy: 0.0,
              speed: speed,
              speedAccuracy: 0.0,
              timestamp: timestamp,
            );

            if (mounted) {
              setState(() => _driverPosition = pos);
              await _updateNavAnnotation();
              _updateRoute(); // throttled internally

              // Auto-pan camera to follow driver unless user has panned away
              if (_followDriver && _mapboxMap != null) {
                _isProgrammaticMove = true;
                _mapboxMap!.setCamera(CameraOptions(
                  center: _latlng(pos.latitude, pos.longitude),
                  bearing: pos.heading,
                ));
                Future.delayed(const Duration(milliseconds: 150),
                    () => _isProgrammaticMove = false);
              }
            }
          }
        } catch (_) {}
      }

      // Initial fetch
      await fetchOnce();

      // Poll every 5 seconds for updated bus position
      _locationUpdateTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => fetchOnce());
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Mapbox map callbacks
  // ══════════════════════════════════════════════════════════════════════════════

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

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
      center =
          _latlng(_driverPosition!.latitude, _driverPosition!.longitude);
    } else if (_mappableStudents.isNotEmpty) {
      center = _latlng(
        _mappableStudents.first['lat'] as double,
        _mappableStudents.first['lng'] as double,
      );
    }
    if (center != null) {
      _isProgrammaticMove = true;
      _mapboxMap!.flyTo(
        CameraOptions(center: center, zoom: 14.5),
        MapAnimationOptions(duration: 800),
      );
      Future.delayed(const Duration(milliseconds: 900),
          () => _isProgrammaticMove = false);
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
    setState(() => _selectedStudent = student);
    _mapboxMap?.flyTo(
      CameraOptions(
        center: _latlng(student['lat'] as double, student['lng'] as double),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 400),
    );
    _placeHomeMarkers();
    _sheetController.animateTo(
      0.38,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _recenterOnDriver() {
    if (_driverPosition == null || _mapboxMap == null) return;
    _isProgrammaticMove = true;
    setState(() => _followDriver = true);
    _mapboxMap!.flyTo(
      CameraOptions(
        center:
            _latlng(_driverPosition!.latitude, _driverPosition!.longitude),
        zoom: 15.0,
        bearing: _driverPosition!.heading,
      ),
      MapAnimationOptions(duration: 500),
    );
    Future.delayed(const Duration(milliseconds: 600),
        () => _isProgrammaticMove = false);
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
              const SnackBar(
                content: Text('No active trip found. Please start a trip first.'),
                backgroundColor: AppTheme.warningState,
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
                const SnackBar(
                  content: Text('Trip has already ended. Returning to start shift.'),
                  backgroundColor: AppTheme.warningState,
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
            const SnackBar(
              content: Text('Cannot verify trip status with server. Using local data.'),
              backgroundColor: AppTheme.warningState,
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
            const SnackBar(
              content: Text('Error loading trip. Please try again.'),
              backgroundColor: AppTheme.criticalAlert,
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

      final userName = prefs.getString('user_name') ?? 'Driver';
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

        final rawStops = (tripData['stops'] as List? ?? [])
            .cast<Map<String, dynamic>>();

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

        // Build child_id → stop order map so the student list matches pickup sequence
        final Map<int, int> childStopOrder = {};
        for (final stop in rawStops) {
          final stopOrder = stop['order'] as int? ?? 999;
          for (final childId
              in (stop['childrenIds'] as List? ?? []).cast<int>()) {
            childStopOrder[childId] = stopOrder;
          }
        }

        if (childStopOrder.isNotEmpty) {
          _students.sort((a, b) {
            final aId = int.tryParse(a['id'].toString()) ?? 0;
            final bId = int.tryParse(b['id'].toString()) ?? 0;
            return (childStopOrder[aId] ?? 999)
                .compareTo(childStopOrder[bId] ?? 999);
          });
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
          "driverName": "Driver",
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

  Future<void> _onPickupStatusChanged(int index, bool isPickedUp) async {
    setState(() => _students[index]["isPickedUp"] = isPickedUp);
    _placeHomeMarkers();
    // Force a fresh route calculation excluding the now-picked-up student
    _lastRouteRefresh = null;
    _updateRoute();

    try {
      final studentId = _students[index]["id"];
      final prefs = await SharedPreferences.getInstance();
      final tripType = prefs.getString('current_trip_type') ?? 'pickup';
      await _apiService.markAttendance(
        childId: studentId,
        status: isPickedUp ? 'picked_up' : 'pending',
        tripType: tripType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  isPickedUp
                      ? '${_students[index]["name"]} marked as picked up'
                      : '${_students[index]["name"]} marked as not picked up',
                ),
              ),
            ]),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.successAction,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 2.w),
              const Expanded(child: Text('Saved locally. Will sync when online.')),
            ]),
            duration: const Duration(seconds: 3),
            backgroundColor: AppTheme.warningState,
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
        title: const Text('End Trip'),
        content: const Text(
            'Are you sure you want to end this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endTrip();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalAlert),
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
          const SnackBar(
            content: Text('Trip ended successfully'),
            backgroundColor: AppTheme.successAction,
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
              Icon(Icons.warning, color: AppTheme.criticalAlert),
              SizedBox(width: 2.w),
              const Expanded(child: Text('Failed to End Trip')),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Could not connect to server to end trip.'),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.warningState.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningState),
                  ),
                  child: const Text(
                    '• Try Again: Attempt to end trip again\n• Force End Locally: Stop timer and location tracking',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Try Again'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningState),
                child: const Text('Force End Locally'),
              ),
            ],
          ),
        );

        if (shouldForceEnd == true) {
          await _clearTripStateLocally();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip ended locally. Location tracking stopped.'),
                backgroundColor: AppTheme.warningState,
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

  Future<void> _updateRoute() async {
    if (_driverPosition == null || _polylineAnnotationManager == null) return;

    // Throttle: at most once every 45 seconds.
    // Only stamp _lastRouteRefresh when we actually hit the Directions API so
    // early returns (no GPS, no manager, or empty student list) do NOT eat up
    // the 45-second window.
    final now = DateTime.now();
    if (_lastRouteRefresh != null &&
        now.difference(_lastRouteRefresh!) <
            const Duration(seconds: 45)) return;

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

    // Mapbox Directions v5 allows max 25 waypoints (driver + 24 stops).
    final capped = pending.length > 24 ? pending.sublist(0, 24) : pending;

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
          'steps': 'false',
          'access_token': ApiConfig.mapboxAccessToken,
        },
      ).timeout(const Duration(seconds: 10));

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
        newEtas[capped[i]['id'] as String] =
            Duration(seconds: cumSecs.round());
      }

      if (mounted) {
        setState(() {
          _studentEtas
            ..clear()
            ..addAll(newEtas);
        });
      }
      print('✅ _updateRoute: polyline drawn, ${newEtas.length} ETAs set');
    } on DioException catch (e) {
      print('❌ _updateRoute DioException: ${e.message} | ${e.response?.statusCode} | ${e.response?.data}');
      // Network unavailable — keep existing route/ETAs
      _lastRouteRefresh = null; // allow retry next call
    } catch (e) {
      print('❌ _updateRoute error: $e');
      _lastRouteRefresh = null; // allow retry next call
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Theme(
        data: AppTheme.lightDriverTheme,
        child: const Scaffold(
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
        ),
      );
    }

    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        drawer: DriverDrawerWidget(
          currentRoute: '/driver-active-trip-screen',
          driverData: {
            'name': _tripData['driverName'] ?? 'Driver',
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
                zoom: 14.5,
              ),
              onMapCreated: _onMapCreated,
              onScrollListener: (_) {
                // Only disengage follow when the user actually pans,
                // not when we move the camera programmatically.
                if (_followDriver && !_isProgrammaticMove && mounted) {
                  setState(() => _followDriver = false);
                }
              },
            ),

            // ── Trip timer badge (top-center) ──────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
              left: 72,
              right: 72,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                  onPickupToggle: _onPickupStatusChanged,
                  onEndTrip: _onEndTripPressed,
                );
              },
            ),
          ],
        ),
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
  final Function(int, bool) onPickupToggle;
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
            child: Divider(
                color: Colors.white.withValues(alpha: 0.12), height: 1),
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

          // Student tiles
          ...students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            final eta = studentEtas[student['id'] as String?];
            return _StudentTripTile(
              student: student,
              index: index,
              isSelected: selectedStudent?['id'] == student['id'],
              eta: eta,
              onTap: student['lat'] != null ? () => onStudentTap(student) : null,
              onToggle: (val) => onPickupToggle(index, val),
            );
          }),

          SizedBox(height: 2.h),

          // End Trip button
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 3.h),
            child: ElevatedButton.icon(
              onPressed: onEndTrip,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text(
                'End Trip',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalAlert,
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
  final int index;
  final bool isSelected;
  final Duration? eta;
  final VoidCallback? onTap;
  final ValueChanged<bool> onToggle;

  const _StudentTripTile({
    required this.student,
    required this.index,
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

    final Color statusColor = isPickedUp
        ? const Color(0xFF10B981)
        : const Color(0xFF6B7280);

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
                      style:
                          TextStyle(color: Colors.white54, fontSize: 9.sp),
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
