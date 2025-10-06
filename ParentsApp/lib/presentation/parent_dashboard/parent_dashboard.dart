import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../notifications_center/notifications_center.dart';
import '../parent_profile_settings/parent_profile_settings.dart';
import './widgets/child_status_card.dart';
import './widgets/connection_status_bar.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  bool _isConnected = true;
  String _lastUpdated = '2 min ago';

  // Mock data for multiple children - Ugandan families
  final List<Map<String, dynamic>> _childrenData = [
    {
      "id": 1,
      "name": "Muhanguzi Ampire",
      "grade": "7",
      "school": "Kampala Parents School",
      "photo":
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "status": "on_bus",
      "arrivalTime": "Arriving in 12 min",
      "progress": 0.65,
      "busNumber": "KPS-07",
      "driverName": "Mr. Okello",
      "route": "Kololo Route"
    },
    {
      "id": 2,
      "name": "Nakanwagi Omanya",
      "grade": "4",
      "school": "Kampala Parents School",
      "photo":
          "https://images.unsplash.com/photo-1547036967-23d11aacaee0?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "status": "at_school",
      "arrivalTime": "Pickup at 3:30 PM",
      "progress": 0.0,
      "busNumber": "KPS-04",
      "driverName": "Mrs. Namuddu",
      "route": "Nakasero Route"
    },
    {
      "id": 3,
      "name": "Kateregga Ssemakula",
      "grade": "10",
      "school": "Kampala Parents School",
      "photo":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      "status": "waiting",
      "arrivalTime": "Bus arriving in 5 min",
      "progress": 0.0,
      "busNumber": "KPS-10",
      "driverName": "Mr. Mutumba",
      "route": "Ntinda Route"
    }
  ];

  @override
  void initState() {
    super.initState();
    _simulateConnectionStatus();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning!',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Your Children',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            _isConnected = true;
            _lastUpdated = 'Just now';
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Children Status',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Children status cards
              ..._childrenData
                  .map(
                    (childData) => GestureDetector(
                      onTap: () => _onChildStatusTap(childData),
                      child: ChildStatusCard(childData: childData),
                    ),
                  )
                  .toList(),
              SizedBox(height: 10.h), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  void _onChildStatusTap(Map<String, dynamic> childData) {
    final String status = childData['status'] ?? '';
    final String childName = childData['name'] ?? 'Child';

    if (status == 'on_bus' || status == 'waiting') {
      // Navigate to live bus tracking map
      Navigator.pushNamed(
        context,
        '/live-bus-tracking-map',
        arguments: childData,
      );
    } else {
      // Show status info for other statuses
      _showChildStatusInfo(childData);
    }
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
