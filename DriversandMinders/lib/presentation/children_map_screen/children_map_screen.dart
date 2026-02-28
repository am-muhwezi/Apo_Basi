import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../config/api_config.dart';

/// Full-screen Mapbox map showing each child's home location with a draggable
/// bottom sheet for child details.
class ChildrenMapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final Map<String, dynamic> tripData;

  const ChildrenMapScreen({
    super.key,
    required this.students,
    required this.tripData,
  });

  @override
  State<ChildrenMapScreen> createState() => _ChildrenMapScreenState();
}

class _ChildrenMapScreenState extends State<ChildrenMapScreen>
    implements OnPointAnnotationClickListener {
  // Mapbox SDK
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _homeAnnotationManager;
  PointAnnotationManager? _busAnnotationManager;

  // Map annotation ID → student lookup (for tap handling)
  final Map<String, Map<String, dynamic>> _annotationToStudent = {};

  // Marker images (rendered once at startup)
  Map<String, Uint8List> _homeMarkerImages = {}; // keyed by status string
  Uint8List? _busMarkerImage;

  // Driver GPS position
  geo.Position? _driverPosition;
  StreamSubscription<geo.Position>? _positionStream;
  PointAnnotation? _busAnnotation;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Map<String, dynamic>? _selectedStudent;

  List<Map<String, dynamic>> get _mappableStudents => widget.students
      .where((s) => s['lat'] != null && s['lng'] != null)
      .toList();

  @override
  void initState() {
    super.initState();
    _renderMarkerImages();
    _initDriverLocation();
    if (_mappableStudents.isNotEmpty) {
      _selectedStudent = _mappableStudents.first;
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Marker image rendering ──────────────────────────────────────────────────

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
    final busIcon = await _renderBusIcon();

    if (mounted) {
      setState(() {
        _homeMarkerImages = {
          'home': home,
          'on_bus': onBus,
          'at_school': atSchool,
        };
        _busMarkerImage = busIcon;
      });
    }

    // Place markers if map is already ready
    await _placeHomeMarkers();
    await _updateBusAnnotation();
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

    // White outline
    canvas.drawCircle(Offset(cx, cy), r + 3, Paint()..color = Colors.white);
    // Pin head
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = pinColor);
    // Tapered tip
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

  Future<Uint8List> _renderBusIcon() async {
    const double size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0xFF1A1A2E),
    );

    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(Icons.directions_bus.codePoint),
        style: TextStyle(
          fontSize: size * 0.55,
          fontFamily: Icons.directions_bus.fontFamily,
          package: Icons.directions_bus.fontPackage,
          color: const Color(0xFF3B82F6),
          height: 1.0,
        ),
      )
      ..layout();
    tp.paint(
      canvas,
      Offset(size / 2 - tp.width / 2, size / 2 - tp.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _initDriverLocation() async {
    try {
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.always ||
          permission == geo.LocationPermission.whileInUse) {
        try {
          final pos = await geo.Geolocator.getCurrentPosition(
            locationSettings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          if (mounted) setState(() => _driverPosition = pos);
          await _updateBusAnnotation();
        } catch (_) {}

        _positionStream = geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 20,
          ),
        ).listen((pos) {
          if (mounted) setState(() => _driverPosition = pos);
          _updateBusAnnotation();
        });
      }
    } catch (_) {}
  }

  // ── Mapbox map callbacks ───────────────────────────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    _homeAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _busAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    _homeAnnotationManager!.addOnPointAnnotationClickListener(this);

    // Markers may already be rendered; place them now
    await _placeHomeMarkers();
    await _updateBusAnnotation();

    // Fly to initial position
    _centerMapInitially();
  }

  void _centerMapInitially() {
    if (_mapboxMap == null) return;
    Point? center;
    if (_driverPosition != null) {
      center = _latLngToPoint(_driverPosition!.latitude, _driverPosition!.longitude);
    } else if (_selectedStudent != null) {
      center = _latLngToPoint(
        _selectedStudent!['lat'] as double,
        _selectedStudent!['lng'] as double,
      );
    } else if (_mappableStudents.isNotEmpty) {
      center = _latLngToPoint(
        _mappableStudents.first['lat'] as double,
        _mappableStudents.first['lng'] as double,
      );
    }
    if (center != null) {
      _mapboxMap!.flyTo(
        CameraOptions(center: center, zoom: 13.5),
        MapAnimationOptions(duration: 800),
      );
    }
  }

  // ── Annotation helpers ─────────────────────────────────────────────────────

  Point _latLngToPoint(double lat, double lng) =>
      Point(coordinates: Position(lng, lat));

  Future<void> _placeHomeMarkers() async {
    if (_homeAnnotationManager == null || _homeMarkerImages.isEmpty) return;
    _annotationToStudent.clear();
    await _homeAnnotationManager!.deleteAll();

    for (final student in _mappableStudents) {
      final lat = student['lat'] as double;
      final lng = student['lng'] as double;
      final locationStatus =
          (student['locationStatus'] as String? ?? 'home').toLowerCase();
      final isPickedUp = student['isPickedUp'] as bool? ?? false;

      String imageKey;
      if (isPickedUp || locationStatus == 'on-bus' || locationStatus == 'on_bus') {
        imageKey = 'on_bus';
      } else if (locationStatus == 'at-school' || locationStatus == 'at_school') {
        imageKey = 'at_school';
      } else {
        imageKey = 'home';
      }

      final image = _homeMarkerImages[imageKey] ?? _homeMarkerImages['home']!;
      final isSelected = _selectedStudent?['id'] == student['id'];

      final annotation = await _homeAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: _latLngToPoint(lat, lng),
          image: image,
          iconSize: isSelected ? 1.2 : 0.9,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
      _annotationToStudent[annotation.id] = student;
    }
  }

  Future<void> _updateBusAnnotation() async {
    if (_busAnnotationManager == null ||
        _busMarkerImage == null ||
        _driverPosition == null) return;

    final point =
        _latLngToPoint(_driverPosition!.latitude, _driverPosition!.longitude);

    if (_busAnnotation != null) {
      _busAnnotation!.geometry = point;
      _busAnnotation!.iconRotate = _driverPosition!.heading;
      await _busAnnotationManager!.update(_busAnnotation!);
    } else {
      _busAnnotation = await _busAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: point,
          image: _busMarkerImage,
          iconSize: 0.8,
          iconAnchor: IconAnchor.CENTER,
          iconRotate: _driverPosition!.heading,
        ),
      );
    }
  }

  // ── OnPointAnnotationClickListener ────────────────────────────────────────

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
        center: _latLngToPoint(
            student['lat'] as double, student['lng'] as double),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 400),
    );

    // Refresh markers to update selected icon size
    _placeHomeMarkers();

    _sheetController.animateTo(
      0.28,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _recenterOnDriver() {
    if (_driverPosition == null || _mapboxMap == null) return;
    _mapboxMap!.flyTo(
      CameraOptions(
        center: _latLngToPoint(
            _driverPosition!.latitude, _driverPosition!.longitude),
        zoom: 14.0,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Point get _initialCenter {
    if (_selectedStudent != null) {
      return _latLngToPoint(
        _selectedStudent!['lat'] as double,
        _selectedStudent!['lng'] as double,
      );
    }
    if (_mappableStudents.isNotEmpty) {
      return _latLngToPoint(
        _mappableStudents.first['lat'] as double,
        _mappableStudents.first['lng'] as double,
      );
    }
    return _latLngToPoint(0.3476, 32.5825); // Kampala fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Mapbox vector map
          MapWidget(
            styleUri: 'mapbox://styles/${ApiConfig.mapboxStyleId}',
            cameraOptions: CameraOptions(
              center: _initialCenter,
              zoom: 13.5,
            ),
            onMapCreated: _onMapCreated,
          ),

          // Back button – top left
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _CircleButton(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),

          // Re-center button – top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _CircleButton(
              onTap: _recenterOnDriver,
              child: Icon(
                Icons.my_location,
                color: _driverPosition != null
                    ? const Color(0xFF2563EB)
                    : Colors.white,
                size: 22,
              ),
            ),
          ),

          // Draggable bottom sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.15,
            maxChildSize: 0.78,
            snap: true,
            snapSizes: const [0.28, 0.55, 0.78],
            builder: (context, scrollController) {
              return _BottomSheet(
                scrollController: scrollController,
                selectedStudent: _selectedStudent,
                students: widget.students,
                mappableCount: _mappableStudents.length,
                tripData: widget.tripData,
                onStudentTap: _onStudentSelected,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final Map<String, dynamic>? selectedStudent;
  final List<Map<String, dynamic>> students;
  final int mappableCount;
  final Map<String, dynamic> tripData;
  final ValueChanged<Map<String, dynamic>> onStudentTap;

  const _BottomSheet({
    required this.scrollController,
    required this.selectedStudent,
    required this.students,
    required this.mappableCount,
    required this.tripData,
    required this.onStudentTap,
  });

  @override
  Widget build(BuildContext context) {
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

          if (selectedStudent != null)
            _SelectedChildTile(student: selectedStudent!, tripData: tripData)
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              child: Text(
                'Tap a marker to see details',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
            ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Divider(
                color: Colors.white.withValues(alpha: 0.12), height: 1),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
            child: Row(
              children: [
                Text(
                  'All Students',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
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

          ...students.map((s) => _StudentListTile(
                student: s,
                isSelected: selectedStudent?['id'] == s['id'],
                onTap: s['lat'] != null ? () => onStudentTap(s) : null,
              )),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

// ── Selected child hero tile ──────────────────────────────────────────────────

class _SelectedChildTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> tripData;

  const _SelectedChildTile({required this.student, required this.tripData});

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String? ?? 'Unknown';
    final locationStatus =
        (student['locationStatus'] as String? ?? 'home').toLowerCase();
    final isPickedUp = student['isPickedUp'] as bool? ?? false;

    String statusLabel;
    if (isPickedUp || locationStatus == 'on-bus' || locationStatus == 'on_bus') {
      statusLabel = 'is On Bus';
    } else if (locationStatus == 'at-school' || locationStatus == 'at_school') {
      statusLabel = 'is At School';
    } else {
      statusLabel = 'is Home';
    }

    final busNumber = tripData['busNumber']?.toString() ??
        tripData['bus_number']?.toString() ??
        'N/A';
    final routeName =
        tripData['routeName']?.toString() ?? tripData['route_name']?.toString();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name $statusLabel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Container(
                width: 14.w,
                height: 14.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF2563EB), width: 2.5),
                  color: const Color(0xFF1E3A5F),
                ),
                child:
                    const Icon(Icons.person, color: Colors.white70, size: 28),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus,
                            color: Colors.white, size: 14),
                        SizedBox(width: 1.w),
                        Text(
                          busNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      const Icon(Icons.route, color: Colors.white54, size: 14),
                      SizedBox(width: 1.w),
                      Text(
                        routeName ?? 'Route not yet assigned',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Student list tile ──────────────────────────────────────────────────────────

class _StudentListTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StudentListTile({
    required this.student,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String? ?? 'Unknown';
    final grade = student['grade'] as String? ?? '';
    final address = student['stopName'] as String? ?? '';
    final isPickedUp = student['isPickedUp'] as bool? ?? false;
    final locationStatus =
        (student['locationStatus'] as String? ?? 'home').toLowerCase();
    final hasCoordsSet = student['lat'] != null && student['lng'] != null;

    Color statusColor;
    String statusText;
    if (isPickedUp || locationStatus == 'on-bus' || locationStatus == 'on_bus') {
      statusColor = const Color(0xFF3B82F6);
      statusText = 'On Bus';
    } else if (locationStatus == 'at-school' || locationStatus == 'at_school') {
      statusColor = const Color(0xFF10B981);
      statusText = 'At School';
    } else {
      statusColor = const Color(0xFF6B7280);
      statusText = 'At Home';
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.4.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB).withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.25),
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
                      'Grade $grade • $address',
                      style: TextStyle(color: Colors.white54, fontSize: 9.5.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!hasCoordsSet) ...[
              SizedBox(width: 1.5.w),
              const Icon(Icons.location_off, color: Colors.white24, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Circle FAB button ────────────────────────────────────────────────────────

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
