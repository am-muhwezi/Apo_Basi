import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
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
  bool _isConnected = true;
  String _lastUpdated = '2 min ago';

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Child> _children = [];
  String? _error;
  String _parentName = 'Parent';

  @override
  void initState() {
    super.initState();
    _loadData();
    _simulateConnectionStatus();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both parent profile and children
      final parentProfile = await _apiService.getParentProfile();
      final children = await _apiService.getMyChildren();

      setState(() {
        // Get name from user object
        final user = parentProfile['user'];
        if (user != null) {
          _parentName = user['first_name'] ?? user['username'] ?? 'Parent';
        } else {
          _parentName = 'Parent';
        }
        _children = children;
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
    await _loadData();
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
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          const NotificationsCenter(),
          const ParentProfileSettings(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            AppTheme.lightTheme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'home',
              color: _currentIndex == 0
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
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
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF4CAF50), // Green
                                      const Color(0xFF388E3C), // Darker green
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 2.h),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Greeting text
                                      Text(
                                        'Good Morning ${_parentName.toUpperCase()}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      // Date and time row
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: Colors.white,
                                            size: 4.w,
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            _getFormattedDate(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white,
                                            size: 4.w,
                                          ),
                                          SizedBox(width: 2.w),
                                          Text(
                                            _getFormattedTime(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.sp,
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
                                padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
                                child: Text(
                                  'Your Children',
                                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.lightTheme.colorScheme.onSurface,
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
                                      onTap: () => _onChildCardTap(_childToCardData(child)),
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
    };
  }

  void _onChildCardTap(Map<String, dynamic> childData) {
    // Navigate to child detail screen
    // The card's onTap will only be called if status is trackable (not at_home, at_school, or no record)
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
            Icon(Icons.error_outline, size: 64, color: AppTheme.lightTheme.colorScheme.error),
            SizedBox(height: 2.h),
            Text(
              'Error Loading Children',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
            Icon(Icons.family_restroom, size: 64, color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
            SizedBox(height: 2.h),
            Text(
              'No Children Found',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Contact your school admin to add children to your account',
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
    Color statusColor = AppTheme.lightTheme.colorScheme.primary;

    switch (status.toLowerCase()) {
      case 'at_school':
        statusMessage = '$childName is safely at school';
        statusColor = AppTheme.lightTheme.colorScheme.secondary;
        break;
      case 'at_home':
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
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
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
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (childData['arrivalTime'] != null &&
                  childData['arrivalTime'].toString().isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  'Next Update: ${childData['arrivalTime']}',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (childData['busNumber'] != null) ...[
                SizedBox(height: 1.h),
                Text(
                  'Bus: ${childData['busNumber']} • ${childData['driverName'] ?? 'Unknown Driver'}',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
