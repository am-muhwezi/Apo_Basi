import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/trip_state_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/busminder_drawer_widget.dart';
import '../busminder_active_trip_screen/busminder_active_trip_screen.dart';

class BusminderStartShiftScreen extends StatefulWidget {
  const BusminderStartShiftScreen({super.key});

  @override
  State<BusminderStartShiftScreen> createState() =>
      _BusminderStartShiftScreenState();
}

class _BusminderStartShiftScreenState extends State<BusminderStartShiftScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isLoadingData = true;
  String _currentTime = '';
  Timer? _timeTimer;
  final ApiService _apiService = ApiService();
  final TripStateService _tripStateService = TripStateService();

  late AnimationController _pulseController;

  Map<String, dynamic>? _minderData;
  Map<String, dynamic>? _busData;
  List<Map<String, dynamic>> _assignedChildren = [];

  String _selectedTripType = 'pickup';

  bool _hasActiveTrip = false;
  Map<String, dynamic>? _activeTripInfo;

  // Attendance-focused readiness checks
  final Map<int, bool> _readinessStates = {};

  final List<Map<String, dynamic>> _readinessItems = [
    {"title": "Attendance Sheet Ready", "icon": Icons.fact_check_outlined},
    {"title": "Communication Device", "icon": Icons.phone_android_outlined},
    {"title": "Emergency Contacts List", "icon": Icons.contact_phone_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    for (int i = 0; i < _readinessItems.length; i++) {
      _readinessStates[i] = false;
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
      _loadMinderData(),
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
      MaterialPageRoute(
          builder: (context) => const BusminderActiveTripScreen()),
    );
  }

  Future<void> _loadMinderData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Assistant';
      final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

      // Try to get cached data first
      final cachedBusData = prefs.getString('cached_bus_data');

      if (cachedBusData != null) {
        try {
          final busDataJson = jsonDecode(cachedBusData);
          _busData = busDataJson is Map<String, dynamic> ? busDataJson : null;
        } catch (_) {}
      }

      // Try to fetch from API
      try {
        final busesData = await _apiService.getBusMinderBuses();
        final buses = busesData['buses'] as List<dynamic>?;

        if (buses != null && buses.isNotEmpty) {
          _busData = buses[0] as Map<String, dynamic>;
          await prefs.setString('cached_bus_data', jsonEncode(_busData));

          // Fetch children for this bus
          final busId = _busData?['id'];
          if (busId != null) {
            final childrenData = await _apiService.getBusChildren(busId);
            _assignedChildren = childrenData.map((child) {
              return {
                'id': child['id']?.toString() ?? '',
                'name':
                    '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}',
                'grade': child['grade']?.toString() ??
                    child['class_grade']?.toString() ??
                    'N/A',
              };
            }).toList();
          }
        }
      } catch (apiError) {
        // Use cached data if API fails
      }

      _minderData = {
        "minderId": userId,
        "minderName": userName,
        "busNumber":
            _busData?['bus_number'] ?? _busData?['number_plate'] ?? 'No Bus',
        "busPlate": _busData?['number_plate'] ?? 'N/A',
        "studentCount": _assignedChildren.length,
        "isAssigned": _busData != null,
      };

      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      _initializeFallbackData();
    }
  }

  Future<void> _initializeFallbackData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Assistant';
    final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

    setState(() {
      _minderData = {
        "minderId": userId,
        "minderName": userName,
        "busNumber": "Not Assigned",
        "busPlate": "N/A",
        "studentCount": 0,
        "isAssigned": false,
      };
      _assignedChildren = [];
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
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

  Future<void> _beginAttendance() async {
    final tripType = _selectedTripType;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final busId = _busData?['id'];
      final busNumber =
          _busData?['bus_number'] ?? _busData?['number_plate'] ?? 'Bus';

      if (busId == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No bus assigned. Cannot start attendance.'),
              backgroundColor: AppTheme.criticalAlert,
            ),
          );
        }
        return;
      }

      // Save using both key sets for compatibility
      await prefs.setInt('current_bus_id', busId);
      await prefs.setInt('bus_id', busId);
      await prefs.setString('current_trip_type', tripType);
      await prefs.setString('trip_type', tripType);
      await prefs.setString(
          'trip_start_time', DateTime.now().toIso8601String());
      await prefs.setBool('trip_in_progress', true);
      await prefs.setBool('trip_active', true);
      await prefs.setString('bus_number', busNumber.toString());

      setState(() {
        _isLoading = false;
        _hasActiveTrip = true;
        _activeTripInfo = {
          'tripType': tripType,
          'busId': busId,
        };
      });

      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const BusminderActiveTripScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to start attendance: ${e.toString()}'),
              backgroundColor: AppTheme.criticalAlert),
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
            Text('Reset Shift State?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            SizedBox(height: 1.h),
            Text(
                'This will clear local attendance data. Only use if the app is stuck.',
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
                        content: Text('Shift state reset'),
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
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }

  bool get _canBeginAttendance =>
      _minderData?['isAssigned'] == true && _busData?['id'] != null;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightBusminderTheme,
      child: Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        drawer: BusminderDrawerWidget(
            currentRoute: '/busminder-start-shift-screen'),
        body: _isLoadingData ? _buildLoadingState() : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(
            color: AppTheme.primaryBusminder, strokeWidth: 3),
        SizedBox(height: 2.h),
        Text('Loading...', style: TextStyle(color: AppTheme.textSecondary)),
      ]),
    );
  }

  Widget _buildMainContent() {
    final name = _minderData?['minderName'] as String? ?? 'Assistant';

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 2.h),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreetingCard(name),
                      SizedBox(height: 3.h),
                      if (_minderData?['isAssigned'] != true)
                        _buildNotAssignedCard()
                      else ...[
                        _buildAssignmentCard(),
                        SizedBox(height: 3.h),
                      ],
                      _buildSectionTitle(
                          'Students Preview', Icons.people_outline),
                      SizedBox(height: 1.5.h),
                      _buildStudentPreviewCard(),
                      SizedBox(height: 3.h),
                      _buildSectionTitle(
                          'Attendance Type', Icons.swap_vert_rounded),
                      SizedBox(height: 1.5.h),
                      _buildAttendanceTypeSelector(),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Builder(
              builder: (context) => Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.menu_rounded,
                        color: AppTheme.textPrimary, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String name) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded,
                  color: AppTheme.textPrimary, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open navigation drawer',
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: AppTheme.primaryBusminder.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.access_time,
                  size: 16, color: AppTheme.primaryBusminder),
              SizedBox(width: 6),
              Text(_currentTime,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBusminder)),
            ]),
          ),
        ],
      ),
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
      child: Row(
        children: [
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
                        : AppTheme.primaryBusminder.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: _hasActiveTrip
                              ? AppTheme.successAction
                              : AppTheme.primaryBusminder,
                          shape: BoxShape.circle)),
                  SizedBox(width: 6),
                  Text(
                      _hasActiveTrip
                          ? 'Attendance Active'
                          : 'Ready for Attendance',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _hasActiveTrip
                              ? AppTheme.successAction
                              : AppTheme.primaryBusminder)),
                ]),
              ),
            ]),
          ),
          // Attendance clipboard icon for bus minder
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppTheme.primaryBusminder.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.assignment_outlined,
                  size: 28, color: AppTheme.primaryBusminder)),
        ],
      ),
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
              letterSpacing: 0.5))
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
                    AppTheme.primaryBusminder,
                    AppTheme.primaryBusminder.withOpacity(0.7)
                  ]),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.directions_bus_rounded,
                  size: 24, color: Colors.white)),
          SizedBox(width: 4.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_minderData?['busNumber'] ?? 'Bus',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text('Assigned Bus',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ])),
        ]),
        SizedBox(height: 3.h),
        Row(children: [
          _buildInfoPill(Icons.people_outline,
              '${_minderData?['studentCount'] ?? 0}', 'Students'),
          SizedBox(width: 3.w),
          _buildInfoPill(
              Icons.badge_outlined, _minderData?['busPlate'] ?? 'N/A', 'Plate'),
        ]),
      ]),
    );
  }

  Widget _buildInfoPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.primaryBusminder.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 20, color: AppTheme.primaryBusminder),
          SizedBox(width: 8),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildStudentPreviewCard() {
    final totalStudents = _assignedChildren.length;

    if (totalStudents == 0) {
      return Container(
        padding: EdgeInsets.all(5.w),
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
          Icon(Icons.people_outline, size: 40, color: Colors.grey.shade300),
          SizedBox(height: 1.h),
          Text('No students assigned',
              style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      );
    }

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: Offset(0, 4))
          ]),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryBusminder.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.people_outline,
                color: AppTheme.primaryBusminder, size: 24),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Students',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$totalStudents students',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildAttendanceTypeChip(
            type: 'pickup',
            label: 'Pickup',
            subtitle: 'Morning',
            icon: Icons.wb_sunny_outlined,
            color: AppTheme.primaryBusminder,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildAttendanceTypeChip(
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

  Widget _buildAttendanceTypeChip({
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
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
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

  Widget _buildBottomButton() {
    // If there's an active trip, show Continue Trip button (always enabled)
    // Otherwise show Begin Attendance button (enabled based on assignment)
    final canStart = _hasActiveTrip || _canBeginAttendance;

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
            return GestureDetector(
              onTap: canStart && !_isLoading
                  ? () {
                      if (_hasActiveTrip) {
                        _continueTrip();
                      } else {
                        _beginAttendance();
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
                              : AppTheme.primaryBusminder,
                          _hasActiveTrip
                              ? AppTheme.successAction.withOpacity(0.8)
                              : AppTheme.primaryBusminderLight,
                        ])
                      : null,
                  color: canStart ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canStart
                      ? [
                          BoxShadow(
                            color: (_hasActiveTrip
                                    ? AppTheme.successAction
                                    : AppTheme.primaryBusminder)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
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
                                  : 'Begin Attendance',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
