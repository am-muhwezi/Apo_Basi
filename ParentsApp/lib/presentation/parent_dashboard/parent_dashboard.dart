import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/cache_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/home_location_service.dart';
import '../../models/child_model.dart';
import '../notifications_center/notifications_center.dart';
import '../parent_profile_settings/parent_profile_settings.dart';
import './widgets/child_status_card.dart';
import './widgets/home_location_prompt_dialog.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  bool _isConnected = true;

  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final HomeLocationService _homeLocationService = HomeLocationService();
  bool _isLoading = true;
  List<Child> _children = [];
  String _parentName = 'Parent';
  bool _hasCheckedHomeLocation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    Future.microtask(() {
      _initializeConnectivity();
      _checkAndPromptHomeLocation();
    });
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();
    _connectivityService.onConnectionRestored = () {
      if (mounted) {
        setState(() => _isConnected = true);
        _showToast('Connection restored', isError: false);
        _loadData();
      }
    };
    _connectivityService.onConnectionLost = () {
      if (mounted) {
        setState(() => _isConnected = false);
        _showToast('Currently offline', isError: true);
      }
    };
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFFF9500) : const Color(0xFF34C759),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _loadData() async {
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
      setState(() => _parentName = cachedParentName);
    }

    try {
      final parentProfile = await _apiService.getParentProfile();
      final children = await _apiService.getMyChildren();
      await _cacheService.cacheChildren(children.map((c) => c.toJson()).toList());

      if (mounted) {
        setState(() {
          final user = parentProfile['user'];
          if (user != null) {
            _parentName = user['first_name'] ?? user['username'] ?? 'Parent';
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
      if (_children.isNotEmpty) {
        if (mounted) {
          _showToast('Currently offline', isError: true);
          setState(() { _isLoading = false; _isConnected = false; });
        }
      } else {
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
          if (mounted) {
            setState(() { _isLoading = false; _isConnected = false; });
            _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
          }
        }
      }
    }
  }

  Future<void> _checkAndPromptHomeLocation() async {
    if (_hasCheckedHomeLocation) return;
    _hasCheckedHomeLocation = true;
    await Future.delayed(const Duration(milliseconds: 500));
    final coordinates = await _homeLocationService.getHomeCoordinates();
    if (coordinates == null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => HomeLocationPromptDialog(
          onLocationSet: () => _showToast('Home location saved successfully', isError: false),
        ),
      );
    }
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RepaintBoundary(key: const ValueKey('home'), child: _buildHomeScreen()),
          RepaintBoundary(
            key: const ValueKey('notifications'),
            child: _visitedTabs.contains(1) ? const NotificationsCenter() : const SizedBox.shrink(),
          ),
          RepaintBoundary(
            key: const ValueKey('profile'),
            child: _visitedTabs.contains(2) ? const ParentProfileSettings() : const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ──────────────────────────── HOME SCREEN ─────────────────────────────────

  Widget _buildHomeScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverAppBar(colorScheme, isDark),

          SliverToBoxAdapter(child: _buildWelcomeSection(colorScheme)),

          // Children's Status header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.group_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Children's Status",
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_children.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyView(colorScheme))
          else
            SliverList(
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

          SliverToBoxAdapter(child: _buildRouteStatus(colorScheme, isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(ColorScheme colorScheme, bool isDark) {
    final appBarBg = isDark ? AppTheme.surfaceDark : Colors.white;
    final initial = _parentName.isNotEmpty ? _parentName[0].toUpperCase() : 'P';

    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: appBarBg,
      surfaceTintColor: Colors.transparent,
      shadowColor: colorScheme.onSurface.withValues(alpha: 0.08),
      elevation: 1,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/AB_logo.jpg',
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_bus_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'ApoBasi',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
      actions: [
        // Parent initial avatar
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $_parentName',
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your daily guardian's compass is ready.",
            style: GoogleFonts.inter(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStatus(ColorScheme colorScheme, bool isDark) {
    final cardBg = isDark
        ? AppTheme.cardDark
        : const Color(0xFFEFF4FF);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline_rounded,
                color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route Status',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All routes are currently running on time. No delays reported.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.family_restroom_rounded,
                size: 40, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            'No Children Found',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact your school admin to add children to your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── BOTTOM NAV ──────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.dividerDark.withValues(alpha: 0.5)
                : const Color(0xFFC3C6D7).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'HOME',
                selected: _currentIndex == 0,
                onTap: () => _onNavTap(0),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications_rounded,
                label: 'UPDATES',
                selected: _currentIndex == 1,
                onTap: () => _onNavTap(1),
                showBadge: _hasUnreadNotifications(),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'PROFILE',
                selected: _currentIndex == 2,
                onTap: () => _onNavTap(2),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  // ──────────────────────────── HELPERS ─────────────────────────────────────

  Map<String, dynamic> _childToCardData(Child child) {
    return {
      'id': child.id,
      'name': child.fullName,
      'grade': child.classGrade,
      'status': child.currentStatus ?? 'no record today',
      'busId': child.assignedBus?.id,
      'busNumber': child.assignedBus?.numberPlate,
      'routeName': child.routeName,
      'driverName': child.driverName,
    };
  }

  void _onChildCardTap(Map<String, dynamic> childData) {
    Navigator.pushNamed(context, '/child-detail', arguments: childData);
  }

  bool _hasUnreadNotifications() => false;
}

// ──────────────────────────── NAV ITEM WIDGET ─────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;
  final ColorScheme colorScheme;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? (selectedIcon ?? icon) : icon,
                  color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
