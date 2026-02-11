import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../services/connectivity_service.dart';
import '../../models/child_model.dart';
import '../notifications_center/notifications_center.dart';
import '../parent_profile_settings/parent_profile_settings.dart';
import './widgets/child_status_card.dart';
import './widgets/connection_status_bar.dart';
import './widgets/telegram_background.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0}; // Only build tabs when first visited
  bool _isConnected = true;
  String _lastUpdated = '2 min ago';

  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isLoading = true;
  List<Child> _children = [];
  String _parentName = 'Parent';

  @override
  void initState() {
    super.initState();
    // Load data first (from cache), then initialize connectivity
    _loadData();

    // Defer connectivity initialization to reduce startup load
    Future.microtask(() {
      _initializeConnectivity();
    });
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    _connectivityService.onConnectionRestored = () {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
        _showToast('Connection restored', isError: false);
        _loadData();
      }
    };
    _connectivityService.onConnectionLost = () {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
        _showToast('Currently offline', isError: true);
      }
    };
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF9500) : const Color(0xFF34C759),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadData() async {
    // First, load from cache immediately (including parent name)
    final prefs = await SharedPreferences.getInstance();
    final cachedParentName = prefs.getString('parent_first_name') ?? '';
    final cachedChildren = await _cacheService.getCachedChildren();

    if (cachedChildren != null && cachedChildren.isNotEmpty) {
      setState(() {
        _children = cachedChildren.map((json) => Child.fromJson(json)).toList();
        if (cachedParentName.isNotEmpty) _parentName = cachedParentName;
        _isLoading = false;
      });
    } else if (cachedParentName.isNotEmpty) {
      // No cached children yet but name is known — show it without waiting for API
      setState(() {
        _parentName = cachedParentName;
      });
    }

    // Then fetch fresh data in background
    try {
      final parentProfile = await _apiService.getParentProfile();
      final children = await _apiService.getMyChildren();

      // Cache the fresh data
      await _cacheService.cacheChildren(children.map((c) => c.toJson()).toList());

      if (mounted) {
        setState(() {
          // Get name from user object
          final user = parentProfile['user'];
          if (user != null) {
            _parentName = user['first_name'] ?? user['username'] ?? 'Parent';
            // Cache parent name for offline use
            prefs.setString('parent_first_name', _parentName);
          } else {
            _parentName = 'Parent';
          }
          _children = children;
          _isLoading = false;
          _isConnected = true;
          _lastUpdated = 'Just now';
        });
      }
    } catch (e) {
      // If we have cached data, just show a toast
      if (_children.isNotEmpty) {
        if (mounted) {
          _showToast('Currently offline', isError: true);
          setState(() {
            _isLoading = false;
            _isConnected = false;
          });
        }
      } else {
        // No cached data, try to load stale cache
        final staleCache = await _cacheService.getStaleChildren();
        if (staleCache != null && staleCache.isNotEmpty) {
          if (mounted) {
            setState(() {
              _children = staleCache.map((json) => Child.fromJson(json)).toList();
              _isLoading = false;
              _isConnected = false;
            });
            _showToast('Currently offline', isError: true);
          }
        } else {
          // Absolutely no data available
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isConnected = false;
            });
            _showToast(
              e.toString().replaceAll('Exception: ', ''),
              isError: true,
            );
          }
        }
      }
    }
  }

  Future<void> _loadChildren() async {
    await _loadData();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navBarTheme = theme.bottomNavigationBarTheme;
    final primaryColor = navBarTheme.selectedItemColor ?? colorScheme.primary;
    final inactiveColor =
        navBarTheme.unselectedItemColor ?? colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RepaintBoundary(
            key: const ValueKey('home'),
            child: _buildHomeScreen(),
          ),
          RepaintBoundary(
            key: const ValueKey('notifications'),
            child: _visitedTabs.contains(1)
                ? const NotificationsCenter()
                : const SizedBox.shrink(),
          ),
          RepaintBoundary(
            key: const ValueKey('profile'),
            child: _visitedTabs.contains(2)
                ? const ParentProfileSettings()
                : const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _visitedTabs.add(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: navBarTheme.backgroundColor ?? colorScheme.surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: inactiveColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _currentIndex == 0 ? primaryColor : inactiveColor,
              size: 6.w,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'notifications',
                  color: _currentIndex == 1 ? primaryColor : inactiveColor,
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
              color: _currentIndex == 2 ? primaryColor : inactiveColor,
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
    // Cache theme colors to avoid repeated lookups
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final brightness = theme.brightness;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
                                  color: brightness == Brightness.dark
                                      ? colorScheme.surface
                                      : colorScheme.surfaceVariant,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colorScheme.outline
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
                                          color: colorScheme.onSurface,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // Date and time
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: colorScheme.onSurfaceVariant,
                                            size: 4.w,
                                          ),
                                          SizedBox(width: 1.5.w),
                                          Text(
                                            _getFormattedDate(),
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
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
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
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
      "routeName":
          child.routeName, // Only route name, not route code (admin only)
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

  Widget _buildEmptyView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom,
                size: 64, color: colorScheme.onSurfaceVariant),
            SizedBox(height: 2.h),
            Text(
              'No Children Found',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Contact your school admin to add children to your account',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChildStatusInfo(Map<String, dynamic> childData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final String status = childData['status'] ?? '';
    final String childName = childData['name'] ?? 'Child';

    String statusMessage = '';
    Color statusColor = colorScheme.primary;

    switch (status.toLowerCase()) {
      case 'at_school':
      case 'at-school':
        statusMessage = '$childName is safely at school';
        statusColor = colorScheme.secondary;
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
      builder: (BuildContext dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        final dialogColorScheme = dialogTheme.colorScheme;
        final dialogTextTheme = dialogTheme.textTheme;

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
                  style: dialogTextTheme.titleLarge?.copyWith(
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
                style: dialogTextTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (childData['arrivalTime'] != null &&
                  childData['arrivalTime'].toString().isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  'Next Update: ${childData['arrivalTime']}',
                  style: dialogTextTheme.bodyMedium?.copyWith(
                    color: dialogColorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (childData['busNumber'] != null) ...[
                SizedBox(height: 1.h),
                Text(
                  'Bus: ${childData['busNumber']} • ${childData['driverName'] ?? 'Unknown Driver'}',
                  style: dialogTextTheme.bodyMedium?.copyWith(
                    color: dialogColorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
