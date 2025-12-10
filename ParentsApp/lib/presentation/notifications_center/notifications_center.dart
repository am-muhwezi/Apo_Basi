import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import './widgets/empty_notifications_widget.dart';
import './widgets/notification_card_widget.dart';
import './widgets/notification_filter_sheet_widget.dart';
import './widgets/notification_search_bar_widget.dart';

class NotificationsCenter extends StatefulWidget {
  const NotificationsCenter({Key? key}) : super(key: key);

  @override
  State<NotificationsCenter> createState() => _NotificationsCenterState();
}

class _NotificationsCenterState extends State<NotificationsCenter>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  bool _isSearchVisible = false;
  String _searchQuery = '';
  List<String> _selectedFilters = [];
  Map<String, List<Map<String, dynamic>>> _groupedNotifications = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Notifications list - will be populated from API
  List<Map<String, dynamic>> _allNotifications = [];

  // Auto-refresh timer
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotifications();
    _startAutoRefresh();
  }

  // Load notifications from API
  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _apiService.getNotifications();
      final notifications = response['notifications'] as List<dynamic>;

      setState(() {
        _allNotifications = notifications.map((notification) {
          return {
            'id': notification['id'],
            'type': notification['type'] ?? 'general',
            'title': notification['title'] ?? '',
            'message': notification['message'] ?? '',
            'isRead': notification['is_read'] ?? false,
            'timestamp': DateTime.parse(notification['created_at']),
            'expanded': false,
          };
        }).toList();

        _groupNotificationsByDate();
        _isLoading = false;
      });
    } catch (e) {
      if (!silent) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('Error loading notifications: $e');
    }
  }

  // Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _loadNotifications(silent: true);
      }
    });
  }

  // Stop auto-refresh timer
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isSearchVisible) {
      // Auto-hide search when scrolling down
    }
  }

  void _groupNotificationsByDate() {
    _groupedNotifications.clear();
    final filteredNotifications = _getFilteredNotifications();

    for (var notification in filteredNotifications) {
      final date = _getDateKey(notification['timestamp']);
      if (!_groupedNotifications.containsKey(date)) {
        _groupedNotifications[date] = [];
      }
      _groupedNotifications[date]!.add(notification);
    }

    // Sort each group by timestamp (newest first)
    _groupedNotifications.forEach((key, value) {
      value.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    });
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    var filtered = _allNotifications.where((notification) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final title = (notification['title'] ?? '').toLowerCase();
        final message = (notification['message'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !message.contains(query)) {
          return false;
        }
      }

      // Filter by selected types
      if (_selectedFilters.isNotEmpty) {
        return _selectedFilters.contains(notification['type']);
      }

      return true;
    }).toList();

    // Sort by timestamp (newest first)
    filtered.sort((a, b) =>
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return filtered;
  }

  String _getDateKey(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(notificationDate).inDays < 7) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  int get _unreadCount {
    return _allNotifications.where((n) => !(n['isRead'] ?? true)).length;
  }

  void _markAllAsRead() async {
    try {
      await _apiService.markNotificationsAsRead();

      setState(() {
        for (var notification in _allNotifications) {
          notification['isRead'] = true;
        }
      });
      _groupNotificationsByDate();

      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as read: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _groupNotificationsByDate();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _groupNotificationsByDate();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationFilterSheetWidget(
        selectedTypes: _selectedFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _selectedFilters = filters;
            _groupNotificationsByDate();
          });
        },
      ),
    );
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    setState(() {
      notification['expanded'] = !(notification['expanded'] ?? false);
      if (!(notification['isRead'] ?? true)) {
        notification['isRead'] = true;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _markAsRead(Map<String, dynamic> notification) async {
    try {
      await _apiService.markNotificationsAsRead(
        notificationIds: [notification['id']],
      );

      setState(() {
        notification['isRead'] = true;
        _groupNotificationsByDate();
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  void _shareNotification(Map<String, dynamic> notification) {
    // Implement share functionality
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification shared with family'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) async {
    // Save the notification for undo functionality
    final deletedNotification = Map<String, dynamic>.from(notification);

    setState(() {
      _allNotifications.removeWhere((n) => n['id'] == notification['id']);
      _groupNotificationsByDate();
    });
    HapticFeedback.mediumImpact();

    try {
      await _apiService.deleteNotification(notification['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Restore notification on error
      setState(() {
        _allNotifications.add(deletedNotification);
        _allNotifications.sort((a, b) => (b['timestamp'] as DateTime)
            .compareTo(a['timestamp'] as DateTime));
        _groupNotificationsByDate();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete notification: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _contactSchool() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling school transport office...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewOnMap() {
    // Navigate back to dashboard where users can select child to view on map
    Navigator.pop(context);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final hasNotifications = _groupedNotifications.isNotEmpty;

    // Show loading indicator
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Notifications'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error message if any
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Notifications'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Failed to load notifications'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadNotifications,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: CustomIconWidget(
              iconName: _isSearchVisible ? 'close' : 'search',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          if (hasNotifications && _unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          NotificationSearchBarWidget(
            isVisible: _isSearchVisible,
            onSearchChanged: _onSearchChanged,
            onFilterTap: _showFilterSheet,
          ),
          if (_selectedFilters.isNotEmpty) ...[
            Container(
              height: 6.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedFilters.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      margin: EdgeInsets.only(right: 2.w),
                      child: FilterChip(
                        label: Text('Clear All'),
                        onSelected: (_) {
                          setState(() {
                            _selectedFilters.clear();
                            _groupNotificationsByDate();
                          });
                        },
                        backgroundColor: AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.1),
                        labelStyle:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error,
                        ),
                      ),
                    );
                  }

                  final filterType = _selectedFilters[index - 1];
                  return Container(
                    margin: EdgeInsets.only(right: 2.w),
                    child: FilterChip(
                      label: Text(_getFilterLabel(filterType)),
                      selected: true,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilters.remove(filterType);
                          _groupNotificationsByDate();
                        });
                      },
                      selectedColor: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      labelStyle:
                          AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          Expanded(
            child: hasNotifications
                ? RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _groupedNotifications.length,
                      itemBuilder: (context, index) {
                        final dateKey =
                            _groupedNotifications.keys.elementAt(index);
                        final notifications = _groupedNotifications[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index == 0) SizedBox(height: 1.h),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 1.h),
                              child: Text(
                                dateKey,
                                style: AppTheme.lightTheme.textTheme.titleSmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...notifications.map((notification) => Slidable(
                                  key: ValueKey(notification['id']),
                                  startActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      if (!(notification['isRead'] ?? true))
                                        SlidableAction(
                                          onPressed: (_) =>
                                              _markAsRead(notification),
                                          backgroundColor: AppTheme
                                              .lightTheme.colorScheme.secondary,
                                          foregroundColor: Colors.white,
                                          icon: Icons.mark_email_read,
                                          label: 'Read',
                                        ),
                                      SlidableAction(
                                        onPressed: (_) =>
                                            _shareNotification(notification),
                                        backgroundColor: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        icon: Icons.share,
                                        label: 'Share',
                                      ),
                                    ],
                                  ),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      if (notification['type'] != 'emergency')
                                        SlidableAction(
                                          onPressed: (_) =>
                                              _deleteNotification(notification),
                                          backgroundColor: AppTheme
                                              .lightTheme.colorScheme.error,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Delete',
                                        ),
                                    ],
                                  ),
                                  child: NotificationCardWidget(
                                    notification: notification,
                                    onTap: () =>
                                        _onNotificationTap(notification),
                                    onMarkRead: () => _markAsRead(notification),
                                    onShare: () =>
                                        _shareNotification(notification),
                                    onDelete: () =>
                                        _deleteNotification(notification),
                                    onContactSchool: _contactSchool,
                                    onViewOnMap: _viewOnMap,
                                  ),
                                )),
                            if (index == _groupedNotifications.length - 1)
                              SizedBox(height: 4.h),
                          ],
                        );
                      },
                    ),
                  )
                : const EmptyNotificationsWidget(),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filterType) {
    switch (filterType) {
      case 'bus_approaching':
        return 'Bus Approaching';
      case 'pickup_confirmed':
        return 'Pickup Confirmed';
      case 'dropoff_complete':
        return 'Dropoff Complete';
      case 'route_change':
        return 'Route Changes';
      case 'emergency':
        return 'Emergency';
      case 'major_delay':
        return 'Major Delays';
      default:
        return filterType;
    }
  }
}
