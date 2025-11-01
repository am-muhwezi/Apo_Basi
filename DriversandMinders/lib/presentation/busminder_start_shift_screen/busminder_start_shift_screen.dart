import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/busminder_drawer_widget.dart';

class BusminderStartShiftScreen extends StatefulWidget {
  const BusminderStartShiftScreen({super.key});

  @override
  State<BusminderStartShiftScreen> createState() =>
      _BusminderStartShiftScreenState();
}

class _BusminderStartShiftScreenState
    extends State<BusminderStartShiftScreen> {
  bool _isLoading = false;
  bool _isLoadingData = true;
  String _currentTime = '';
  Timer? _timeTimer;
  final ApiService _apiService = ApiService();

  // Busminder data fetched from API
  Map<String, dynamic>? _busminderData;
  List<dynamic>? _assignedBuses;
  Map<String, dynamic>? _selectedBus;
  String? _selectedTripType;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimeUpdates();
    _loadBusminderData();
  }

  Future<void> _loadBusminderData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      // Get user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Busminder';
      final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

      // Try to get busminder's buses information from API
      try {
        final busesResponse = await _apiService.getBusMinderBuses();

        // Extract buses data
        _assignedBuses = busesResponse['buses'] as List<dynamic>?;

        if (_assignedBuses != null && _assignedBuses!.isNotEmpty) {
          _selectedBus = _assignedBuses![0] as Map<String, dynamic>;
        }

        // Build busminder data object
        _busminderData = {
          "busminderId": userId,
          "busminderName": userName,
          "busesCount": _assignedBuses?.length ?? 0,
        };
      } catch (apiError) {
        // API call failed, use fallback data
        print('API Error: $apiError');
        await _initializeFallbackData();
        setState(() {
          _errorMessage =
              'Could not connect to server. Using offline mode.\n${apiError.toString()}';
        });
      }

      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load busminder data: ${e.toString()}';
        _isLoadingData = false;

        // Fallback to minimal data from SharedPreferences
        _initializeFallbackData();
      });
    }
  }

  Future<void> _initializeFallbackData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? 'Busminder';
    final userId = prefs.getInt('user_id')?.toString() ?? 'N/A';

    setState(() {
      _busminderData = {
        "busminderId": userId,
        "busminderName": userName,
        "busesCount": 0,
      };

      _assignedBuses = [];
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  void _startTimeUpdates() {
    _updateCurrentTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCurrentTime();
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _beginShift() async {
    if (_selectedBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bus first'),
          backgroundColor: AppTheme.criticalAlert,
        ),
      );
      return;
    }

    if (_selectedTripType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select trip type (Pickup or Dropoff)'),
          backgroundColor: AppTheme.criticalAlert,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate shift initialization
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    HapticFeedback.heavyImpact();

    // Save trip type and bus to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_trip_type', _selectedTripType!);
    await prefs.setInt('current_bus_id', _selectedBus!['id'] as int);

    // Navigate to attendance screen
    Navigator.pushReplacementNamed(
      context,
      '/busminder-attendance-screen',
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
            'Are you sure you want to logout? Any unsaved data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _apiService.clearToken();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/shared-login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalAlert,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  bool get _canBeginShift => _selectedBus != null && _selectedTripType != null;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightBusminderTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        drawer: BusminderDrawerWidget(
          currentRoute: '/busminder-start-shift-screen',
        ),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBusminder,
          elevation: 0,
          title: Text(
            _currentTime,
            style: const TextStyle(
              color: AppTheme.textOnPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _showLogoutConfirmation,
              icon: const Icon(
                Icons.logout,
                color: AppTheme.textOnPrimary,
              ),
            ),
          ],
        ),
        body: _isLoadingData
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primaryBusminder,
                    ),
                    SizedBox(height: 2.h),
                    const Text('Loading busminder information...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          SizedBox(height: 2.h),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 2.h),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBusminder,
                            ),
                            child: const Text('Continue Anyway'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryBusminder,
                                AppTheme.primaryBusminderLight,
                              ],
                            ),
                          ),
                          padding: EdgeInsets.all(6.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: AppTheme.textOnPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                _busminderData?['busminderName'] as String? ??
                                    'Busminder',
                                style: const TextStyle(
                                  color: AppTheme.textOnPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'ID: ${_busminderData?['busminderId'] ?? 'N/A'}',
                                style: TextStyle(
                                  color:
                                      AppTheme.textOnPrimary.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 3.h),

                        // Start Shift Card
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  AppTheme.primaryBusminder.withValues(alpha: 0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryBusminder.withValues(alpha: 0.15),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBusminder.withValues(alpha: 0.08),
                                  offset: const Offset(0, 8),
                                  blurRadius: 24,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(5.w),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.primaryBusminder,
                                            AppTheme.primaryBusminderLight,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryBusminder.withValues(alpha: 0.3),
                                            offset: Offset(0, 4),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.directions_bus,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Shift',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Text(
                                            'Select bus and trip type',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 3.h),

                                // Bus Selection
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundSecondary.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.primaryBusminder.withValues(alpha: 0.08),
                                      width: 1,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(4.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.bus_alert,
                                            color: AppTheme.primaryBusminder,
                                            size: 20,
                                          ),
                                          SizedBox(width: 2.w),
                                          const Text(
                                            'Select Bus',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2.h),
                                      if (_assignedBuses != null &&
                                          _assignedBuses!.isNotEmpty)
                                        ...(_assignedBuses!.map((bus) {
                                          final busMap =
                                              bus as Map<String, dynamic>;
                                          final isSelected =
                                              _selectedBus?['id'] ==
                                                  busMap['id'];
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedBus = busMap;
                                              });
                                              HapticFeedback.selectionClick();
                                            },
                                            child: Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 2.h),
                                              padding: EdgeInsets.all(4.w),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppTheme.primaryBusminder
                                                        .withValues(alpha: 0.1)
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppTheme
                                                          .primaryBusminder
                                                      : AppTheme.borderLight,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(2.w),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? AppTheme
                                                              .primaryBusminder
                                                          : AppTheme
                                                              .backgroundSecondary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      isSelected
                                                          ? Icons.check_circle
                                                          : Icons
                                                              .radio_button_unchecked,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : AppTheme
                                                              .textSecondary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  SizedBox(width: 3.w),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          busMap['number_plate']
                                                                  as String? ??
                                                              'Bus',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isSelected
                                                                ? AppTheme
                                                                    .primaryBusminder
                                                                : AppTheme
                                                                    .textPrimary,
                                                          ),
                                                        ),
                                                        if (busMap['route'] !=
                                                            null)
                                                          Text(
                                                            'Route: ${busMap['route']}',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color: AppTheme
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }))
                                      else
                                        Container(
                                          padding: EdgeInsets.all(4.w),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.orange,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.orange,
                                                size: 24,
                                              ),
                                              SizedBox(width: 3.w),
                                              const Expanded(
                                                child: Text(
                                                  'No buses assigned',
                                                  style: TextStyle(
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 2.h),

                                // Trip Type Selection
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundSecondary.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.primaryBusminder.withValues(alpha: 0.08),
                                      width: 1,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(4.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.swap_horiz,
                                            color: AppTheme.primaryBusminder,
                                            size: 20,
                                          ),
                                          SizedBox(width: 2.w),
                                          const Text(
                                            'Trip Type',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2.h),
                                      Row(
                                        children: [
                                          // Pickup Option
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedTripType = 'pickup';
                                                });
                                                HapticFeedback.selectionClick();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(4.w),
                                                decoration: BoxDecoration(
                                                  color: _selectedTripType ==
                                                          'pickup'
                                                      ? AppTheme
                                                          .primaryBusminder
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _selectedTripType ==
                                                            'pickup'
                                                        ? AppTheme
                                                            .primaryBusminder
                                                        : AppTheme.borderLight,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.home_outlined,
                                                      color:
                                                          _selectedTripType ==
                                                                  'pickup'
                                                              ? Colors.white
                                                              : AppTheme
                                                                  .primaryBusminder,
                                                      size: 32,
                                                    ),
                                                    SizedBox(height: 1.h),
                                                    Text(
                                                      'Pickup',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: _selectedTripType ==
                                                                'pickup'
                                                            ? Colors.white
                                                            : AppTheme
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Morning Route',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _selectedTripType ==
                                                                'pickup'
                                                            ? Colors.white
                                                                .withValues(alpha: 0.8)
                                                            : AppTheme
                                                                .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 3.w),
                                          // Dropoff Option
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedTripType = 'dropoff';
                                                });
                                                HapticFeedback.selectionClick();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(4.w),
                                                decoration: BoxDecoration(
                                                  color: _selectedTripType ==
                                                          'dropoff'
                                                      ? AppTheme.successAction
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _selectedTripType ==
                                                            'dropoff'
                                                        ? AppTheme.successAction
                                                        : AppTheme.borderLight,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      Icons.school_outlined,
                                                      color:
                                                          _selectedTripType ==
                                                                  'dropoff'
                                                              ? Colors.white
                                                              : AppTheme
                                                                  .successAction,
                                                      size: 32,
                                                    ),
                                                    SizedBox(height: 1.h),
                                                    Text(
                                                      'Dropoff',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: _selectedTripType ==
                                                                'dropoff'
                                                            ? Colors.white
                                                            : AppTheme
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Afternoon Route',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _selectedTripType ==
                                                                'dropoff'
                                                            ? Colors.white
                                                                .withValues(alpha: 0.8)
                                                            : AppTheme
                                                                .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 3.h),

                        // Begin Shift Button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: _canBeginShift
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.primaryBusminder,
                                        AppTheme.primaryBusminderLight,
                                      ],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _canBeginShift
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryBusminder.withValues(alpha: 0.3),
                                        offset: Offset(0, 4),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: _canBeginShift ? _beginShift : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _canBeginShift ? Colors.transparent : AppTheme.textSecondary.withValues(alpha: 0.3),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 2.w),
                                        const Text(
                                          'Begin Shift',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        SizedBox(height: 2.h),

                        // Info Message
                        if (!_canBeginShift)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      'Please select both bus and trip type to begin',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
      ),
    );
  }
}
