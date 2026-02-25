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
import './widgets/bus_approaching_card.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0}; // Only build tabs when first visited
  bool _isConnected = true;

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

  Widget _buildHomeScreen() {
    final theme = Theme.of(context);

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
                        // Welcome header
                        SliverToBoxAdapter(
                          child: _buildWelcomeHeader(),
                        ),
                        // Bus approaching card (conditional)
                        SliverToBoxAdapter(
                          child: BusApproachingCard(
                            approachingChildren: _getApproachingChildren(),
                          ),
                        ),
                        // Section header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Text(
                              "Children's Bus Status",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        // Children cards
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final child = _children[index];
                                final cardData = _childToCardData(child);
                                return ChildStatusCard(
                                  childData: cardData,
                                  onTrackLive: () => _onChildCardTap(cardData),
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

  Widget _buildWelcomeHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Welcome, $_parentName',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          // Avatar circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : const Color(0xFFF9E4F1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _parentName.isNotEmpty ? _parentName[0].toUpperCase() : 'P',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getApproachingChildren() {
    final approaching = <Map<String, dynamic>>[];
    for (final child in _children) {
      final status = (child.currentStatus ?? '').toLowerCase();
      if (status == 'on_bus' || status == 'on-bus' ||
          status == 'picked_up' || status == 'picked-up') {
        approaching.add({
          'firstName': child.firstName,
          'busNumber': child.assignedBus?.numberPlate,
        });
      }
    }
    return approaching;
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

  bool _hasUnreadNotifications() {
    // TODO: Connect to API to check for unread notifications
    return false; // No notifications yet
  }
}
