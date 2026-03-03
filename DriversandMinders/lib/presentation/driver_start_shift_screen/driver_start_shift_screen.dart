import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/gps_stream_service.dart';
import '../../services/native_location_service.dart';
import '../../widgets/driver_drawer_widget.dart';
import '../../services/trip_state_service.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../driver_active_trip_screen/driver_active_trip_screen.dart';

class DriverStartShiftScreen extends StatefulWidget {
  const DriverStartShiftScreen({super.key});

  @override
  State<DriverStartShiftScreen> createState() => _DriverStartShiftScreenState();
}

class _DriverStartShiftScreenState extends State<DriverStartShiftScreen>
    with SingleTickerProviderStateMixin {
  bool _isGpsConnected = false;
  bool _isLocationEnabled = false;
  bool _isChecklistComplete = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String _currentTime = '';
  String _accuracyText = 'Searching...';
  Timer? _timeTimer;
  // Local listener on the shared GpsStreamService — cancel on dispose,
  // but never stop the singleton (other screens may still be listening).
  StreamSubscription<Position>? _gpsListener;
  final GpsStreamService _gps = GpsStreamService();
  final ApiService _apiService = ApiService();
  final TripStateService _tripStateService = TripStateService();
  final NativeLocationService _nativeLocationService = NativeLocationService();

  late AnimationController _pulseController;

  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _busData;
  Map<String, dynamic>? _routeDetails;
  List<Map<String, dynamic>> _assignedChildren = [];
  String? _errorMessage;

  String _selectedTripType = 'pickup';

  bool _hasActiveTrip = false;
  Map<String, dynamic>? _activeTripInfo;

  bool _isOnline = true;
  bool _isServerReachable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;

  final Map<int, bool> _checklistStates = {};

  final List<Map<String, dynamic>> _checklistItems = [
    {"title": "Vehicle Exterior", "icon": "directions_bus_outlined"},
    {"title": "Interior Safety", "icon": "health_and_safety_outlined"},
    {"title": "Engine & Fluids", "icon": "oil_barrel_outlined"},
    {"title": "Communication", "icon": "wifi_tethering"},
    {"title": "Safety Equipment", "icon": "security_outlined"},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    for (int i = 0; i < _checklistItems.length; i++) {
      _checklistStates[i] = false;
    }

    _startTimeUpdates();

    // Quick synchronous check for active trip from local storage
    _checkForActiveTripSync();

    // Monitor network connectivity
    _initConnectivity();

    // Defer heavy operations until after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  Future<void> _initConnectivity() async {
    // Check current connectivity
    final result = await Connectivity().checkConnectivity();
    _handleConnectivityChange(result);

    // Listen for changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    final nowOnline = results.any((r) => r != ConnectivityResult.none);
    if (mounted) setState(() => _isOnline = nowOnline);
    // Silently refresh when network connection is restored
    if (!wasOnline && nowOnline) {
      _loadDriverData();
    }
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    // One-shot timer: schedule a single reconnect attempt in 30 seconds.
    // If that attempt also fails, _loadDriverData will call _startRetryTimer
    // again, keeping the cycle going.  Using Timer (not Timer.periodic) avoids
    // phantom fires while a slow API call is already in flight.
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _loadDriverData();
    });
  }

  /// Run all async initialization in parallel after first frame
  Future<void> _initializeAsync() async {
    // Run all independent async operations in parallel
    await Future.wait([
      _checkLocationPermission(),
      _loadDriverData(),
      _checkForActiveTrip(),
    ], eagerError: false); // Continue even if one fails
  }

  void _checkForActiveTripSync() {
    SharedPreferences.getInstance().then((prefs) {
      final tripInProgress = prefs.getBool('trip_in_progress') ?? false;
      final tripActive = prefs.getBool('trip_active') ?? false;
      final tripId = prefs.getInt('current_trip_id') ?? prefs.getInt('trip_id');
      final tripType =
          prefs.getString('current_trip_type') ?? prefs.getString('trip_type');

      // Check either flag for active trip
      if (tripInProgress || tripActive) {
        setState(() {
          _hasActiveTrip = true;
          _activeTripInfo = {
            'tripId': tripId,
            'tripType': tripType ?? 'unknown'
          };
        });
      }
    });
  }

  Future<void> _checkForActiveTrip() async {
    try {
      final hasLocalTrip = await _tripStateService.hasActiveTrip();
      final localTripInfo = await _tripStateService.getActiveTripInfo();

      if (hasLocalTrip) {
        try {
          final backendTrip = await _apiService.getActiveTrip();
          if (backendTrip != null && backendTrip['status'] == 'in-progress') {
            if (!mounted) return;
            setState(() {
              _hasActiveTrip = true;
              _activeTripInfo = localTripInfo;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('current_trip_id', backendTrip['id']);
          } else {
            await _clearStaleLocalTripState();
            if (!mounted) return;
            setState(() {
              _hasActiveTrip = false;
              _activeTripInfo = null;
            });
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _hasActiveTrip = true;
            _activeTripInfo = localTripInfo;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _hasActiveTrip = false;
          _activeTripInfo = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasActiveTrip = false;
        _activeTripInfo = null;
      });
    }
  }

  Future<void> _clearStaleLocalTripState() async {
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

  Future<void> _continueTrip() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DriverActiveTripScreen()),
    );
  }

  Future<void> _loadDriverData() async {
    // Only show full loading spinner when there is no data yet.
    // During pull-to-refresh (_driverData already set) keep content visible
    // so the RefreshIndicator animation stays visible above the list.
    setState(() {
      if (_driverData == null) _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // 'user_name' is set by phone login; 'driver_name' by magic-link login.
      // Fall back to driver_name so both auth paths show the real name.
      final userName = (prefs.getString('user_name')?.isNotEmpty == true
              ? prefs.getString('user_name')
              : prefs.getString('driver_name')) ??
          'Driver';
      final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

      final cachedBusData = prefs.getString('cached_bus_data');
      final cachedRouteData = prefs.getString('cached_route_data');
      final hasCachedData = cachedBusData != null && cachedRouteData != null;

      if (hasCachedData) {
        try {
          final busDataJson = jsonDecode(cachedBusData!);
          final routeDataJson = jsonDecode(cachedRouteData!);
          _busData = busDataJson is Map<String, dynamic> ? busDataJson : null;
          _routeDetails =
              routeDataJson is Map<String, dynamic> ? routeDataJson : null;

          if (_routeDetails?['children'] != null &&
              _routeDetails!['children'] is List) {
            final Map<String, Map<String, dynamic>> byId = {};
            for (var child in _routeDetails!['children']) {
              final String id = child['id']?.toString() ?? '';
              if (id.isEmpty) continue;
              byId[id] = {
                'id': id,
                'name':
                    '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
                'grade': child['grade']?.toString() ??
                    child['class_grade']?.toString() ??
                    'N/A',
              };
            }
            _assignedChildren = byId.values.toList();
          }

          _driverData = {
            "driverId": userId,
            "driverName": userName,
            "busNumber": _busData?['bus_number'] ?? 'No Bus',
            "busPlate": _busData?['number_plate'] ?? 'N/A',
            "routeName": _routeDetails?['route_name'] ??
                _routeDetails?['name'] ??
                'No Route',
            "routeAssignment": _busData?['bus_number'] ?? 'No Bus',
            "estimatedDuration": "Calculating...",
            "studentCount":
                _routeDetails?['total_children'] ?? _assignedChildren.length,
          };
          // Show cached data immediately, continue to fetch fresh below
          setState(() => _isLoadingData = false);
        } catch (_) {}
      }

      try {
        final busResponse = await _apiService.getDriverBus();
        final routeResponse = await _apiService.getDriverRoute();

        // Persist name from API so all auth paths stay fresh
        final apiName = busResponse['driver_name'] as String?;
        if (apiName != null && apiName.isNotEmpty) {
          await prefs.setString('user_name', apiName);
          await prefs.setString('driver_name', apiName);
        }
        final freshName = apiName?.isNotEmpty == true ? apiName! : userName;

        _busData = busResponse['buses'] is Map
            ? busResponse['buses'] as Map<String, dynamic>
            : (busResponse['buses'] is List &&
                    (busResponse['buses'] as List).isNotEmpty
                ? busResponse['buses'][0] as Map<String, dynamic>
                : null);

        _routeDetails = routeResponse;
        await prefs.setString('cached_bus_data', jsonEncode(_busData));
        await prefs.setString('cached_route_data', jsonEncode(_routeDetails));

        if (routeResponse['children'] != null &&
            routeResponse['children'] is List) {
          final Map<String, Map<String, dynamic>> byId = {};
          for (var child in routeResponse['children']) {
            final String id = child['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            byId[id] = {
              'id': id,
              'name':
                  '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
              'grade': child['grade']?.toString() ??
                  child['class_grade']?.toString() ??
                  'N/A',
              'lat': double.tryParse(child['home_latitude']?.toString() ?? ''),
              'lng': double.tryParse(child['home_longitude']?.toString() ?? ''),
            };
          }
          _assignedChildren = byId.values.toList();
        }

        _driverData = {
          "driverId": userId,
          "driverName": freshName,
          "busNumber": _busData?['bus_number'] ?? 'No Bus',
          "busPlate": _busData?['number_plate'] ?? 'N/A',
          "routeName": routeResponse['route_name'] ?? 'No Route',
          "routeAssignment": _busData?['bus_number'] ?? 'No Bus',
          "estimatedDuration": "Calculating...",
          "studentCount": _assignedChildren.length,
        };
        _computeMapboxETA();
        // API succeeded — cancel any pending retry and mark server reachable
        _retryTimer?.cancel();
        _retryTimer = null;
        if (mounted) setState(() => _isServerReachable = true);
      } catch (apiError) {
        // API failed — mark server unreachable and start retry timer
        if (mounted) setState(() => _isServerReachable = false);
        _startRetryTimer();
        // Only fall back to "Not Assigned" when there is truly no cached data
        if (!hasCachedData) {
          await _initializeFallbackData();
        }
      }

      if (!mounted) return;
      setState(() => _isLoadingData = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load data';
        _isLoadingData = false;
      });
      _initializeFallbackData();
    }
  }

  Future<void> _initializeFallbackData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('driver_name') ??
        prefs.getString('user_name') ??
        'Driver';
    final userId =
        (prefs.getInt('driver_id') ?? prefs.getInt('user_id'))?.toString() ??
            'N/A';

    if (!mounted) return;
    setState(() {
      _driverData = {
        "driverId": userId,
        "driverName": userName,
        "busNumber": "Not Assigned",
        "busPlate": "N/A",
        "routeName": "Awaiting Assignment",
        "routeAssignment": "Not Assigned Yet",
        "estimatedDuration": "N/A",
        "studentCount": 0,
      };
      _assignedChildren = [];
    });
  }

  Future<void> _refreshDriverData() async {
    return _loadDriverData();
  }

  /// Calls the Mapbox Directions API (driving-traffic) to compute the total
  /// trip duration from the driver's current location through all children's
  /// home stops, then updates the estimatedDuration chip.
  Future<void> _computeMapboxETA() async {
    try {
      // Only proceed if we have children with coordinates
      final stops = _assignedChildren
          .where((c) => c['lat'] != null && c['lng'] != null)
          .toList();
      if (stops.isEmpty) {
        if (mounted) {
          setState(() {
            _driverData?['estimatedDuration'] = 'N/A';
          });
        }
        return;
      }

      // Get current driver location
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        // Location unavailable — still compute using just the stops in order
        if (mounted) setState(() => _driverData?['estimatedDuration'] = 'N/A');
        return;
      }

      // Build coordinate string: driver → stop1 → stop2 → ...
      final coordParts = <String>[
        '${position.longitude},${position.latitude}',
        ...stops.map((s) => '${s['lng']},${s['lat']}'),
      ];
      final coords = coordParts.join(';');

      final token = ApiConfig.mapboxAccessToken;
      final url =
          'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/$coords'
          '?access_token=$token';

      final response = await Dio().get(url);
      if (response.statusCode == 200) {
        final routes = response.data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final durationSec = (routes[0]['duration'] as num).toDouble();
          final minutes = (durationSec / 60).ceil();
          if (mounted) {
            setState(() {
              _driverData?['estimatedDuration'] = '$minutes min';
            });
          }
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _driverData?['estimatedDuration'] = 'N/A');
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _gpsListener?.cancel(); // cancel this screen's listener only — keeps shared stream alive
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimeUpdates() {
    _updateCurrentTime();
    _timeTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateCurrentTime());
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Permission.location.status;
      if (permission.isGranted) await _enableLocationServices();
    } catch (_) {}
  }

  Future<void> _toggleLocationServices() async {
    if (_isLocationEnabled) {
      await _disableLocationServices();
    } else {
      await _enableLocationServices();
    }
  }

  Future<void> _enableLocationServices() async {
    try {
      await Permission.location.request();

      // If the singleton already has a fix, show it immediately — no wait.
      if (_gps.isConnected && _gps.lastKnownPosition != null) {
        setState(() {
          _isLocationEnabled = true;
          _isGpsConnected = true;
          _accuracyText = _gps.accuracyText;
        });
      } else {
        setState(() {
          _isLocationEnabled = true;
          _accuracyText = 'Acquiring...';
        });
      }

      // Start the shared stream (idempotent — safe if already running).
      _gps.ensureStarted();

      // Subscribe this screen's UI to the shared broadcast.
      _gpsListener?.cancel();
      _gpsListener = _gps.stream.listen(
        (Position position) {
          if (!mounted) return;
          setState(() {
            _isGpsConnected = true;
            _accuracyText = _gps.accuracyText;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _isGpsConnected = false;
            _accuracyText = 'Error';
          });
        },
      );
    } catch (_) {
      setState(() {
        _isLocationEnabled = false;
        _isGpsConnected = false;
      });
    }
  }

  Future<void> _disableLocationServices() async {
    _gpsListener?.cancel();
    _gpsListener = null;
    _gps.stop(); // user explicitly disabled — stop the shared stream
    setState(() {
      _isLocationEnabled = false;
      _isGpsConnected = false;
      _accuracyText = 'Disabled';
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Location Required'),
        content: Text('Location access is needed to track the bus route.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Settings')),
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enable Location'),
        content: Text('Please enable location services.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openLocationSettings();
              },
              child: Text('Settings')),
        ],
      ),
    );
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      _checklistStates[index] = !(_checklistStates[index] ?? false);
      _isChecklistComplete = _checklistStates.values.every((v) => v);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _beginRoute() async {
    final tripType = _selectedTripType;
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.startTrip(tripType: tripType);
      final trip = response['trip'];

      if (trip != null && trip['id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final tripId =
            trip['id'] is int ? trip['id'] : int.parse(trip['id'].toString());
        final busId = _busData?['id'];
        final busNumber = _busData?['bus_number'] ?? 'Bus';

        // Save using both key sets for compatibility
        await prefs.setInt('current_trip_id', tripId);
        await prefs.setInt('trip_id', tripId);
        await prefs.setString(
            'current_trip_type', trip['trip_type'] ?? tripType);
        await prefs.setString('trip_type', trip['trip_type'] ?? tripType);
        await prefs.setString(
            'trip_start_time', DateTime.now().toIso8601String());
        await prefs.setBool('trip_in_progress', true);
        await prefs.setBool('trip_active', true);
        if (busId != null) {
          await prefs.setInt(
              'bus_id', busId is int ? busId : int.parse(busId.toString()));
          await prefs.setInt('current_bus_id',
              busId is int ? busId : int.parse(busId.toString()));
        }
        await prefs.setString('bus_number', busNumber.toString());

        try {
          final accessToken = prefs.getString('access_token') ?? '';
          if (accessToken.isNotEmpty && busId != null) {
            await _nativeLocationService.startLocationTracking(
              token: accessToken,
              busId: busId is int ? busId : int.parse(busId.toString()),
              apiUrl: ApiConfig.apiBaseUrl,
            );
          }
        } catch (_) {}

        setState(() => _isLoading = false);
        HapticFeedback.heavyImpact();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const DriverActiveTripScreen()),
          );
        }
      } else {
        throw Exception('Failed to create trip');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final raw = e.toString();
        final message = raw.startsWith('Exception: ')
            ? raw.substring('Exception: '.length)
            : raw;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  void _showResetTripStateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 3.h),
            Icon(Icons.warning_amber_rounded,
                size: 48, color: Theme.of(context).colorScheme.tertiary),
            SizedBox(height: 2.h),
            Text('Reset Trip State?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 1.h),
            Text(
                'This will clear local trip data. Only use if the app is stuck.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text('Cancel',
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)))),
                SizedBox(width: 4.w),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _clearStaleLocalTripState();
                    setState(() {
                      _hasActiveTrip = false;
                      _activeTripInfo = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Trip state reset'),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: Text('Reset',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                )),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'D';
  }

  Widget _buildCompactTripToggle() {
    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(
            child: _buildTripOption('pickup', Icons.wb_sunny_outlined, 'Pickup',
                'Morning', Theme.of(context).colorScheme.primary)),
        Expanded(
            child: _buildTripOption('dropoff', Icons.nights_stay_outlined,
                'Dropoff', 'Afternoon', const Color(0xFF10B981))),
      ]),
    );
  }

  Widget _buildTripOption(
      String type, IconData icon, String label, String sub, Color color) {
    final isSelected = _selectedTripType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTripType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 1.4.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.35), width: 1)
              : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 17,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(sub,
                style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? color.withOpacity(0.7)
                        : Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
          if (isSelected) ...[
            SizedBox(width: 5),
            Icon(Icons.check_circle, size: 14, color: color),
          ],
        ]),
      ),
    );
  }

  IconData _getChecklistIcon(String iconName) {
    switch (iconName) {
      case 'directions_bus_outlined':
        return Icons.directions_bus_outlined;
      case 'health_and_safety_outlined':
        return Icons.health_and_safety_outlined;
      case 'oil_barrel_outlined':
        return Icons.oil_barrel_outlined;
      case 'wifi_tethering':
        return Icons.wifi_tethering;
      case 'security_outlined':
        return Icons.security_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  bool get _canBeginRoute =>
      _isLocationEnabled &&
      _isGpsConnected &&
      _driverData?['routeAssignment'] != 'Not Assigned Yet';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = _driverData?['driverName'] as String? ?? 'Driver';
    return Scaffold(
      drawer: DriverDrawerWidget(
          currentRoute: '/driver-start-shift-screen',
          driverData: _driverData,
          hasActiveTrip: _hasActiveTrip,
          onResetTrip: _showResetTripStateDialog),
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: cs.onSurface),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Text(name.split(' ').first,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isGpsConnected
                  ? cs.secondary.withValues(alpha: 0.12)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isGpsConnected
                    ? cs.secondary.withValues(alpha: 0.3)
                    : cs.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: _isGpsConnected
                          ? cs.secondary
                          : cs.onSurfaceVariant,
                      shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(_currentTime,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isGpsConnected
                          ? cs.secondary
                          : cs.onSurfaceVariant)),
            ]),
          ),
        ],
      ),
      body: _isLoadingData ? _buildLoadingState() : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary, strokeWidth: 3),
          SizedBox(height: 2.h),
          Text('Loading...',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      if (!_isOnline || !_isServerReachable) _buildOfflineBanner(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadDriverData();
            await _checkForActiveTrip();
          },
          color: cs.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                SizedBox(height: 2.h),

                // ── Assignment ──────────────────────────────────────────
                _sectionHeader('Assignment'),
                SizedBox(height: 1.5.h),
                if (_driverData?['routeAssignment'] == 'Not Assigned Yet')
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _buildNotAssignedCard(),
                  )
                else
                  _buildAssignmentCard(),

                SizedBox(height: 2.5.h),
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                SizedBox(height: 2.5.h),

                // ── Location ────────────────────────────────────────────
                _sectionHeader('Location'),
                SizedBox(height: 1.5.h),
                _buildCompactStatusRow(),

                SizedBox(height: 2.5.h),
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                SizedBox(height: 2.5.h),

                // ── Trip Type ───────────────────────────────────────────
                _sectionHeader('Trip Type'),
                SizedBox(height: 1.5.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _buildCompactTripToggle(),
                ),

                SizedBox(height: 2.5.h),
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                SizedBox(height: 2.5.h),

                // ── Pre-Trip Checklist ──────────────────────────────────
                _sectionHeader('Pre-Trip Checklist'),
                SizedBox(height: 1.5.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _buildChecklistCard(),
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
      _buildBottomButton(),
    ]);
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8),
      color: Colors.orange.shade700,
      child: Row(children: [
        Icon(Icons.wifi_off_rounded, size: 14, color: Colors.white),
        SizedBox(width: 6),
        Expanded(
            child: Text('Offline — showing cached data',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500))),
        Text('Pull to refresh',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildAssignmentCard() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Bus row
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: cs.primaryContainer),
                  child: Icon(Icons.directions_bus_rounded,
                      color: cs.primary, size: 22),
                ),
                SizedBox(width: 4.w),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_driverData?['busNumber'] ?? 'Bus',
                          style: tt.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                          'Plate: ${_driverData?['busPlate'] ?? 'N/A'}',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ])),
                if (_hasActiveTrip)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Active',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.secondary)),
                  ),
              ]),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
            // Route row
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: cs.primaryContainer),
                  child:
                      Icon(Icons.route_rounded, color: cs.primary, size: 22),
                ),
                SizedBox(width: 4.w),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_driverData?['routeName'] ?? 'No Route',
                          style: tt.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                          '${_driverData?['studentCount'] ?? 0} students  ·  ${_driverData?['estimatedDuration'] ?? 'N/A'}',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ])),
              ]),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotAssignedCard() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
          color: cs.tertiary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.tertiary.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.warning_amber_rounded,
                color: cs.tertiary, size: 28)),
        SizedBox(width: 4.w),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Not Assigned Yet',
              style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Contact your administrator for a bus assignment',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ])),
      ]),
    );
  }

  Widget _buildCompactStatusRow() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _toggleLocationServices,
          child: Row(children: [
            Icon(
                _isGpsConnected
                    ? Icons.gps_fixed
                    : (_isLocationEnabled
                        ? Icons.gps_not_fixed
                        : Icons.gps_off),
                size: 20,
                color: _isGpsConnected
                    ? cs.secondary
                    : (_isLocationEnabled
                        ? cs.tertiary
                        : cs.onSurfaceVariant)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      _isGpsConnected
                          ? 'GPS Connected'
                          : (_isLocationEnabled
                              ? 'Acquiring GPS...'
                              : 'Location Off'),
                      style:
                          tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  Text(_accuracyText,
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ])),
            Switch(
                value: _isLocationEnabled,
                onChanged: (_) => _toggleLocationServices(),
                activeThumbColor: cs.secondary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ]),
        ),
      ),
    );
  }

  Widget _buildChecklistCard() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        for (int i = 0; i < _checklistItems.length; i++) ...[
          _buildChecklistItem(i),
          if (i < _checklistItems.length - 1)
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
        ],
      ]),
    );
  }

  Widget _buildChecklistItem(int index) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final item = _checklistItems[index];
    final isChecked = _checklistStates[index] ?? false;

    return GestureDetector(
      onTap: () => _toggleChecklistItem(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: isChecked ? cs.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isChecked
                        ? cs.secondary
                        : cs.outline.withValues(alpha: 0.6),
                    width: 2)),
            child: isChecked
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Icon(_getChecklistIcon(item['icon'] as String),
              size: 20,
              color: isChecked ? cs.secondary : cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
              child: Text(item['title'] as String,
                  style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          isChecked ? cs.onSurfaceVariant : cs.onSurface,
                      decoration:
                          isChecked ? TextDecoration.lineThrough : null))),
        ]),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [
        BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, -5))
      ]),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            // Enable button when GPS is connected AND checklist is complete, or there's an active trip
            final canStart =
                (_isGpsConnected && _isChecklistComplete) || _hasActiveTrip;
            return GestureDetector(
              onTap: canStart
                  ? () {
                      if (_hasActiveTrip) {
                        _continueTrip();
                      } else {
                        _beginRoute();
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: canStart
                      ? LinearGradient(colors: [
                          _hasActiveTrip
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                          _hasActiveTrip
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.8)
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.8)
                        ])
                      : null,
                  color: canStart
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canStart
                      ? [
                          BoxShadow(
                              color: (_hasActiveTrip
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.primary)
                                  .withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 4))
                        ]
                      : null,
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(
                                  _hasActiveTrip
                                      ? Icons.play_circle_outline
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24),
                              SizedBox(width: 10),
                              Text(
                                  _hasActiveTrip
                                      ? 'Continue Trip'
                                      : 'Begin Route',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3)),
                            ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
