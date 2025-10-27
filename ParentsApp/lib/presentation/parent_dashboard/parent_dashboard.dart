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

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _simulateConnectionStatus();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final children = await _apiService.getMyChildren();
      setState(() {
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
      body: Column(
        children: [
          if (_currentIndex == 0)
            ConnectionStatusBar(
              isConnected: _isConnected,
              lastUpdated: _lastUpdated,
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeScreen(),
                const NotificationsCenter(),
                const ParentProfileSettings(),
              ],
            ),
          ),
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

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning!',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Your Children',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            onPressed: _loadChildren,
          ),
        ],
      ),
      body: TelegramBackground(
        bubbleColor: AppTheme.lightTheme.colorScheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _children.isEmpty
                    ? _buildEmptyView()
                    : RefreshIndicator(
                        onRefresh: _loadChildren,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 1.h),
                              // Children status cards
                              ..._children
                                  .map(
                                    (child) => ChildStatusCard(
                                      childData: _childToCardData(child),
                                      onTap: () => _onChildCardTap(_childToCardData(child)),
                                    ),
                                  )
                                  .toList(),
                              SizedBox(height: 8.h), // Space for bottom navigation
                            ],
                          ),
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
    final String status = childData['status'] ?? '';

    // Navigate to live bus tracking map for trackable statuses
    // The card's onTap will only be called if status is trackable (not at_home, at_school, or no record)
    Navigator.pushNamed(
      context,
      '/live-bus-tracking-map',
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
    // Simple logic to show notification badge
    return true; // Always show badge for demo
  }
}
