import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
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
  StreamSubscription<Position>? _positionStream;
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

    // Defer heavy operations until after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
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
            setState(() {
              _hasActiveTrip = true;
              _activeTripInfo = localTripInfo;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('current_trip_id', backendTrip['id']);
          } else {
            await _clearStaleLocalTripState();
            setState(() {
              _hasActiveTrip = false;
              _activeTripInfo = null;
            });
          }
        } catch (e) {
          setState(() {
            _hasActiveTrip = true;
            _activeTripInfo = localTripInfo;
          });
        }
      } else {
        setState(() {
          _hasActiveTrip = false;
          _activeTripInfo = null;
        });
      }
    } catch (e) {
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

  Future<void> _loadDriverData({bool forceRemote = false}) async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('driver_name') ??
          prefs.getString('user_name') ??
          'Driver';
      final userId =
          (prefs.getInt('driver_id') ?? prefs.getInt('user_id'))?.toString() ??
              'N/A';

      final cachedBusData = prefs.getString('cached_bus_data');
      final cachedRouteData = prefs.getString('cached_route_data');

      // Use cached data only on initial load; for explicit refresh we
      // always hit the backend to get the latest assignments.
      if (!forceRemote && cachedBusData != null && cachedRouteData != null) {
        try {
          final busDataJson = jsonDecode(cachedBusData);
          final routeDataJson = jsonDecode(cachedRouteData);
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
            // Unified auth may cache a minimal route object with only a `name`.
            // Prefer full `route_name` when present, otherwise fall back to `name`.
            "routeName": _routeDetails?['route_name'] ??
                _routeDetails?['name'] ??
                'No Route',
            "estimatedDuration": _routeDetails?['estimated_duration'] ?? "N/A",
            "studentCount":
                _routeDetails?['total_children'] ?? _assignedChildren.length,
          };

          final bool hasRouteName =
              (_routeDetails?['route_name'] as String?)?.isNotEmpty ?? false;
          final bool hasChildren = _assignedChildren.isNotEmpty;

          // Only short-circuit when we have a full route with children.
          // Otherwise fall through and hydrate from /api/drivers/my-route/.
          if (hasRouteName && hasChildren) {
            setState(() => _isLoadingData = false);
            return;
          }
        } catch (_) {}
      }

      try {
        final busResponse = await _apiService.getDriverBus();
        final routeResponse = await _apiService.getDriverRoute();

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
            };
          }
          _assignedChildren = byId.values.toList();
        }

        _driverData = {
          "driverId": userId,
          "driverName": userName,
          "busNumber": _busData?['bus_number'] ?? 'No Bus',
          "busPlate": _busData?['number_plate'] ?? 'N/A',
          "routeName": routeResponse['route_name'] ?? 'No Route',
          "routeAssignment":
              '${_busData?['bus_number'] ?? 'No Bus'}${routeResponse['route_name'] != null ? ' - ${routeResponse['route_name']}' : ''}',
          "estimatedDuration": routeResponse['estimated_duration'] ?? "N/A",
          "studentCount": _assignedChildren.length,
        };
      } catch (apiError) {
        await _initializeFallbackData();
        final errorString = apiError.toString();
        if (!errorString.contains('not assigned') &&
            !errorString.contains('404')) {
          setState(() => _errorMessage = 'Offline mode - Using cached data');
        }
      }

      setState(() => _isLoadingData = false);
    } catch (e) {
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
    return _loadDriverData(forceRemote: true);
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _positionStream?.cancel();
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
      final permission = await Permission.location.request();

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      setState(() {
        _isLocationEnabled = true;
        _accuracyText = 'Acquiring...';
      });

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen(
        (Position position) {
          setState(() {
            _isGpsConnected = true;
            _accuracyText = '±${position.accuracy.toInt()}m';
          });
        },
        onError: (_) {
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
    _positionStream?.cancel();
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
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(message.isNotEmpty ? message : 'Failed to start trip'),
            backgroundColor: AppTheme.criticalAlert,
          ),
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 3.h),
            Icon(Icons.warning_amber_rounded,
                size: 48, color: AppTheme.warningState),
            SizedBox(height: 2.h),
            Text('Reset Trip State?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            SizedBox(height: 1.h),
            Text(
                'This will clear local trip data. Only use if the app is stuck.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
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
                            style: TextStyle(color: AppTheme.textPrimary)))),
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
                        backgroundColor: AppTheme.successAction));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningState,
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

  Widget _buildTripTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTripTypeChip(
            type: 'pickup',
            label: 'Pickup',
            subtitle: 'Morning',
            icon: Icons.wb_sunny_outlined,
            color: AppTheme.primaryDriver,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildTripTypeChip(
            type: 'dropoff',
            label: 'Dropoff',
            subtitle: 'Afternoon',
            icon: Icons.nights_stay_outlined,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeChip({
    required String type,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTripType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTripType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderLight,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, size: 20, color: color),
          ],
        ),
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
    return Theme(
      data: AppTheme.lightDriverTheme,
      child: Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        drawer: DriverDrawerWidget(
            currentRoute: '/driver-start-shift-screen',
            driverData: _driverData,
            hasActiveTrip: _hasActiveTrip,
            onResetTrip: _showResetTripStateDialog),
        body: _isLoadingData ? _buildLoadingState() : _buildMainContent(),
      ),
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
              color: AppTheme.primaryDriver, strokeWidth: 3),
          SizedBox(height: 2.h),
          Text('Loading...', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final name = _driverData?['driverName'] as String? ?? 'Driver';

    return SafeArea(
        child: Column(children: [
      _buildTopBar(name),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _refreshDriverData,
          color: AppTheme.primaryDriver,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                _buildGreetingCard(name),
                SizedBox(height: 3.h),
                if (_driverData?['routeAssignment'] == 'Not Assigned Yet')
                  _buildNotAssignedCard()
                else ...[_buildAssignmentCard(), SizedBox(height: 3.h)],
                _buildSectionTitle(
                    'Location Status', Icons.location_on_outlined),
                SizedBox(height: 1.5.h),
                _buildLocationCard(),
                SizedBox(height: 3.h),
                _buildSectionTitle('Trip Type', Icons.swap_vert_rounded),
                SizedBox(height: 1.5.h),
                _buildTripTypeSelector(),
                SizedBox(height: 3.h),
                _buildSectionTitle(
                    'Pre-Trip Checklist', Icons.checklist_rounded),
                SizedBox(height: 1.5.h),
                _buildChecklistCard(),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
      _buildBottomButton(),
    ]));
  }

  Widget _buildTopBar(String name) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Row(children: [
        Builder(
            builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2))
                        ]),
                    child: Icon(Icons.menu_rounded,
                        color: AppTheme.textPrimary, size: 22),
                  ),
                )),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: _isGpsConnected
                  ? AppTheme.successAction.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color:
                        _isGpsConnected ? AppTheme.successAction : Colors.grey,
                    shape: BoxShape.circle)),
            SizedBox(width: 8),
            Text(_currentTime,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isGpsConnected
                        ? AppTheme.successAction
                        : AppTheme.textSecondary)),
          ]),
        ),
        Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.primaryDriver,
              AppTheme.primaryDriver.withOpacity(0.7)
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryDriver.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 3))
            ],
          ),
          child: Center(
              child: Text(_getInitials(name),
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14))),
        ),
      ]),
    );
  }

  Widget _buildGreetingCard(String name) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: Offset(0, 4))
          ]),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_getGreeting(),
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text(name.split(' ').first,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _hasActiveTrip
                    ? AppTheme.successAction.withOpacity(0.1)
                    : AppTheme.primaryDriver.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: _hasActiveTrip
                          ? AppTheme.successAction
                          : AppTheme.primaryDriver,
                      shape: BoxShape.circle)),
              SizedBox(width: 6),
              Text(_hasActiveTrip ? 'Trip Active' : 'Ready to Start',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _hasActiveTrip
                          ? AppTheme.successAction
                          : AppTheme.primaryDriver)),
            ]),
          ),
        ])),
        // Avatar/photo beside the name (replace truck icon)
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryDriver,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryDriver.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 3))
            ],
          ),
          child: Center(
              child: Text(_getInitials(name),
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20))),
        ),
      ]),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 18, color: AppTheme.textSecondary),
      SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5)),
    ]);
  }

  Widget _buildNotAssignedCard() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200)),
      child: Row(children: [
        Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 28)),
        SizedBox(width: 4.w),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Not Assigned Yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800)),
          SizedBox(height: 4),
          Text('Contact your administrator for a bus assignment',
              style: TextStyle(fontSize: 13, color: Colors.orange.shade700)),
        ])),
      ]),
    );
  }

  Widget _buildAssignmentCard() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: Offset(0, 4))
          ]),
      child: Column(children: [
        Row(children: [
          Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppTheme.primaryDriver,
                    AppTheme.primaryDriver.withOpacity(0.7)
                  ]),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.directions_bus_rounded,
                  size: 24, color: Colors.white)),
          SizedBox(width: 4.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_driverData?['busNumber'] ?? 'Bus',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(_driverData?['routeName'] ?? 'Route',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ])),
        ]),
        SizedBox(height: 3.h),
        Row(children: [
          Expanded(
            child: _buildInfoPill(Icons.people_outline,
                '${_driverData?['studentCount'] ?? 0}', 'Students'),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildInfoPill(Icons.timer_outlined,
                _driverData?['estimatedDuration'] ?? 'N/A', 'Duration'),
          ),
        ]),
      ]),
    );
  }

  Widget _buildInfoPill(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.primaryDriver.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 20, color: AppTheme.primaryDriver),
        SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLocationCard() {
    return GestureDetector(
      onTap: _toggleLocationServices,
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _isLocationEnabled
                    ? AppTheme.successAction.withOpacity(0.3)
                    : Colors.grey.shade200,
                width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 4))
            ]),
        child: Row(children: [
          Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _isLocationEnabled
                      ? AppTheme.successAction.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                  _isGpsConnected
                      ? Icons.gps_fixed
                      : (_isLocationEnabled
                          ? Icons.gps_not_fixed
                          : Icons.gps_off),
                  size: 24,
                  color: _isGpsConnected
                      ? AppTheme.successAction
                      : (_isLocationEnabled ? Colors.orange : Colors.grey))),
          SizedBox(width: 4.w),
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
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(_accuracyText,
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ])),
          Switch(
              value: _isLocationEnabled,
              onChanged: (_) => _toggleLocationServices(),
              activeThumbColor: AppTheme.successAction),
        ]),
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: Offset(0, 4))
          ]),
      child: Column(children: [
        for (int i = 0; i < _checklistItems.length; i++) ...[
          _buildChecklistItem(i),
          if (i < _checklistItems.length - 1)
            Divider(height: 1, color: Colors.grey.shade100),
        ],
      ]),
    );
  }

  Widget _buildChecklistItem(int index) {
    final item = _checklistItems[index];
    final isChecked = _checklistStates[index] ?? false;

    return GestureDetector(
      onTap: () => _toggleChecklistItem(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: isChecked ? AppTheme.successAction : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isChecked
                        ? AppTheme.successAction
                        : Colors.grey.shade300,
                    width: 2)),
            child: isChecked
                ? Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          SizedBox(width: 14),
          Icon(_getChecklistIcon(item['icon'] as String),
              size: 20,
              color:
                  isChecked ? AppTheme.successAction : AppTheme.textSecondary),
          SizedBox(width: 12),
          Expanded(
              child: Text(item['title'] as String,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isChecked
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      decoration:
                          isChecked ? TextDecoration.lineThrough : null))),
        ]),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                              ? AppTheme.successAction
                              : AppTheme.primaryDriver,
                          _hasActiveTrip
                              ? AppTheme.successAction.withOpacity(0.8)
                              : AppTheme.primaryDriver.withOpacity(0.8)
                        ])
                      : null,
                  color: canStart ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canStart
                      ? [
                          BoxShadow(
                              color: (_hasActiveTrip
                                      ? AppTheme.successAction
                                      : AppTheme.primaryDriver)
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
