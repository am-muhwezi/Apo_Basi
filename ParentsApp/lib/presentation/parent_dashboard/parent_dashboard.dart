import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/home_location_service.dart';
import '../../models/child_model.dart';
import '../notifications_center/notifications_center.dart';
import '../parent_profile_settings/parent_profile_settings.dart';
import './widgets/child_status_card.dart';
import './widgets/home_location_prompt_dialog.dart';
// import './widgets/connection_status_bar.dart'; // not used currently
// Removed legacy telegram-style background to reduce UI redundancy

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  bool _isConnected = true;
  String _lastUpdated = '2 min ago';

  final ApiService _apiService = ApiService();
  final HomeLocationService _homeLocationService = HomeLocationService();
  bool _isLoading = true;
  List<Child> _children = [];
  String? _error;
  String _parentName = 'Parent';
  String? _parentAddress;
  bool _hasShownLocationPrompt = false;

  // Global key to access profile settings state
  final GlobalKey<State> _profileKey = GlobalKey<State>();

  @override
  void initState() {
    super.initState();
    // Defer heavy operations to after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _simulateConnectionStatus();
      _checkAndPromptHomeLocation();
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use consolidated dashboard API endpoint - single call for all data
      final dashboardData = await _apiService.getDashboardData(
        forceRefresh: forceRefresh,
      );

      setState(() {
        // Extract parent data
        final parent = dashboardData['parent'];
        if (parent != null) {
          _parentName = parent['firstName'] ?? 'Parent';
          _parentAddress = parent['address'];
        }

        // Extract children data and convert to Child objects
        final childrenJson = dashboardData['children'] as List<dynamic>?;
        if (childrenJson != null && childrenJson.isNotEmpty) {
          _children = childrenJson.map((json) => Child.fromJson(json)).toList();
        } else {
          _children = [];
        }

        _isLoading = false;
        _isConnected = true;
        _lastUpdated = 'Just now';
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isConnected = false;
        _lastUpdated = 'Failed to update';
      });
    }
  }

  Future<void> _loadChildren() async {
    // Force refresh on pull-to-refresh
    await _loadData(forceRefresh: true);
  }

  /// Check if home location is set, and prompt user if not
  Future<void> _checkAndPromptHomeLocation() async {
    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted || _hasShownLocationPrompt) return;

    try {
      // Check if home location is already cached
      final homeLocation = await _homeLocationService.getHomeCoordinates();
      final homeAddress = await _homeLocationService.getHomeAddress();

      // If neither coordinates nor address are set, show prompt
      if (homeLocation == null && (homeAddress == null || homeAddress.isEmpty)) {
        _hasShownLocationPrompt = true;

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => HomeLocationPromptDialog(
              onLocationSet: () {
                // Refresh children data to update with new address
                _loadChildren();
                // Also refresh profile to show updated address
                if (_profileKey.currentState != null) {
                  (_profileKey.currentState as dynamic).refreshData();
                }
              },
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience
    }
  }

  void _simulateConnectionStatus() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isConnected = !_isConnected;
          _lastUpdated = _isConnected ? 'Just now' : '5 min ago';
        });
        _simulateConnectionStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          const NotificationsCenter(),
          ParentProfileSettings(
            key: _profileKey,
            onRefreshDashboard: _loadData,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Don't auto-refresh tabs - let users pull to refresh instead
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _currentIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'notifications',
                  color: _currentIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
                if (_hasUnreadNotifications())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentIndex == 2
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];

    return '$dayName, $monthName ${now.day}';
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty && _error != null
            ? _buildErrorView()
            : _children.isEmpty
              ? _buildEmptyView()
              : RefreshIndicator(
                        onRefresh: _loadChildren,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Custom header with gradient background
                            SliverToBoxAdapter(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.surface
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Greeting text
                                      Text(
                                        '${_getGreeting()}, $_parentName',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // Date and time
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            size: 4.w,
                                          ),
                                          SizedBox(width: 1.5.w),
                                          Text(
                                            _getFormattedDate(),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Section label with padding
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
                                child: Text(
                                  'Your Children',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 18.sp,
                                      ),
                                ),
                              ),
                            ),
                            // Children cards
                            SliverPadding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final child = _children[index];
                                    return ChildStatusCard(
                                      childData: _childToCardData(child),
                                      onTap: () => _onChildCardTap(
                                          _childToCardData(child)),
                                    );
                                  },
                                  childCount: _children.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Map<String, dynamic> _childToCardData(Child child) {
    return {
      "id": child.id,
      "name": child.fullName,
      "grade": child.classGrade,
      "status": child.currentStatus ?? 'no record today',
      "busId": child.assignedBus?.id,
      "busNumber": child.assignedBus?.numberPlate,
      "driverName": child.assignedBus?.driverName,
      "route": child.assignedBus?.route,
      "routeName": child.assignedBus?.route,  // Add explicit routeName field
      "address": child.address,
      "homeAddress": _parentAddress, // Parent's home address for map
    };
  }

  void _onChildCardTap(Map<String, dynamic> childData) {
    // Always allow parent to open the map screen.
    // The map screen itself will decide whether to show live bus tracking.
    Navigator.pushNamed(
      context,
      '/child-detail',
      arguments: childData,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 2.h),
            Text(
              'Error Loading Children',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _loadChildren,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            SizedBox(height: 2.h),
            Text(
              'No Children Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Contact your school admin to add children to your account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChildStatusInfo(Map<String, dynamic> childData) {
    final String status = childData['status'] ?? '';
    final String childName = childData['name'] ?? 'Child';

    String statusMessage = '';
    Color statusColor = Theme.of(context).colorScheme.primary;

    switch (status.toLowerCase()) {
      case 'at_school':
      case 'at-school':
        statusMessage = '$childName is safely at school';
        statusColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'at_home':
      case 'at-home':
      case 'home':
        statusMessage = '$childName is at home';
        statusColor = const Color(0xFF34C759);
        break;
      default:
        statusMessage =
            '$childName status: ${status.replaceAll('_', ' ').toUpperCase()}';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status == 'at_school' ? Icons.school : Icons.home,
                  color: statusColor,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Status Update',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (childData['arrivalTime'] != null &&
                  childData['arrivalTime'].toString().isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  'Next Update: ${childData['arrivalTime']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (childData['busNumber'] != null) ...[
                SizedBox(height: 1.h),
                Text(
                  'Bus: ${childData['busNumber']} • ${childData['driverName'] ?? 'Unknown Driver'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  bool _hasUnreadNotifications() {
    // TODO: Connect to API to check for unread notifications
    return false; // No notifications yet
  }
}
