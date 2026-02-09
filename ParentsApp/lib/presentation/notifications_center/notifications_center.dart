import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../services/parent_notifications_service.dart';
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
  final ParentNotificationsService _notificationsService =
      ParentNotificationsService();
  bool _isSearchVisible = false;
  String _searchQuery = '';
  List<String> _selectedFilters = [];
  Map<String, List<Map<String, dynamic>>> _groupedNotifications = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Notifications list
  List<Map<String, dynamic>> _allNotifications = [];

  // WebSocket subscriptions
  StreamSubscription? _notificationsSubscription;

  // Auto-refresh timer (for future API integration)
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  // Local storage key for notifications
  static const _notificationsKey = 'cached_notifications';

  // Flag to prevent concurrent setState calls
  bool _isUpdatingState = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Defer heavy operations to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationsFromAPI(); // Load from API first
      _setupNotificationListeners();
    });
  }

  // Load notifications from API
  Future<void> _loadNotificationsFromAPI() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getNotifications();

      // Handle response - could be List or Map with results
      List<dynamic> notificationsList;
      if (response is List) {
        notificationsList = response;
      } else if (response is Map && response.containsKey('results')) {
        notificationsList = response['results'] as List;
      } else if (response is Map) {
        // Response is a map but might be the direct list
        notificationsList = [response];
      } else {
        notificationsList = [];
      }

      setState(() {
        _allNotifications = notificationsList.map((notification) {
          return {
            'id': notification['id'].toString(),
            'type': _normalizeType(notification['notification_type']),
            'title': notification['title'] ?? '',
            'message': notification['message'] ?? '',
            'fullMessage': notification['full_message'],
            'isRead': notification['is_read'] ?? false,
            'timestamp': DateTime.parse(notification['created_at']),
            'expanded': false,
            // Additional data
            'child_name': notification['child_name'],
            'bus_number': notification['bus_number'],
            'additional_data': notification['additional_data'],
          };
        }).toList();

        _groupNotificationsByDate();
        _isLoading = false;
      });

      // Cache the notifications
      await _saveNotifications();
    } catch (e) {
      // Fall back to cached notifications
      await _loadCachedNotifications();
      setState(() {
        _errorMessage = 'Failed to load notifications. Showing cached data.';
      });
    }
  }

  // Start auto-refresh timer
  // Auto-refresh is currently disabled; enable when backend rate limits permit
  // void _startAutoRefresh() {
  //   _refreshTimer = Timer.periodic(_refreshInterval, (_) {
  //     _loadNotificationsFromAPI();
  //   });
  // }

  // Load cached notifications from local storage (fallback)
  Future<void> _loadCachedNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_notificationsKey);

      if (cachedData != null) {
        final List<dynamic> notifications = jsonDecode(cachedData);
        setState(() {
          _allNotifications = notifications.map((notification) {
            return {
              'id': notification['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              'type': notification['type'] ?? 'general',
              'title': notification['title'] ?? '',
              'message': notification['message'] ?? '',
              'isRead': notification['isRead'] ?? false,
              'timestamp': DateTime.parse(notification['timestamp']),
              'expanded': false,
            };
          }).toList();

          _groupNotificationsByDate();
          _isLoading = false;
        });
      } else {
        // No cached notifications
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Setup real-time notification listeners
  void _setupNotificationListeners() {
    // Listen for all incoming notifications from WebSocket
    _notificationsSubscription =
        _notificationsService.allNotificationsStream.listen((data) {
      // Only add notification if widget is mounted and not updating
      if (mounted && !_isUpdatingState) {
        _addNotification({
          'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'type': _normalizeType(data['notification_type']),
          'title': data['title'] ?? 'Notification',
          'message': data['message'] ?? '',
          'fullMessage': data['full_message'],
          'isRead': false,
          'timestamp': data['timestamp'] != null
              ? DateTime.parse(data['timestamp'])
              : DateTime.now(),
          'expanded': false,
          // Store additional data
          'bus_id': data['bus_id'],
          'bus_number': data['bus_number'],
          'child_id': data['child_id'],
          'child_name': data['child_name'],
          'trip_id': data['trip_id'],
        });
      }
    }, onError: (error) {});
  }

  // Add a new notification
  void _addNotification(Map<String, dynamic> notification) {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isUpdatingState) {
        return;
      }

      _isUpdatingState = true;
      try {
        setState(() {
          _allNotifications.insert(
              0, notification); // Add to beginning (newest first)
          _groupNotificationsByDate();
        });

        // Save to local storage
        _saveNotifications();

        // Show a snackbar for new notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification['title']),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        _isUpdatingState = false;
      }
    });
  }

  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _allNotifications.map((notification) {
        return {
          'id': notification['id'],
          'type': notification['type'],
          'title': notification['title'],
          'message': notification['message'],
          'isRead': notification['isRead'],
          'timestamp':
              (notification['timestamp'] as DateTime).toIso8601String(),
        };
      }).toList();

      await prefs.setString(_notificationsKey, jsonEncode(notificationsJson));
    } catch (e) {}
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
    if (_isUpdatingState) return;

    _isUpdatingState = true;
    try {
      // Call API to mark all as read
      try {
        await _apiService.markNotificationsAsRead();
      } catch (e) {}

      if (mounted) {
        setState(() {
          for (var notification in _allNotifications) {
            notification['isRead'] = true;
          }
          _groupNotificationsByDate();
        });
        await _saveNotifications();

        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All notifications marked as read'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      _isUpdatingState = false;
    }
  }

  void _toggleSearch() {
    if (!_isUpdatingState && mounted) {
      _isUpdatingState = true;
      try {
        setState(() {
          _isSearchVisible = !_isSearchVisible;
          if (!_isSearchVisible) {
            _searchQuery = '';
            _groupNotificationsByDate();
          }
        });
      } finally {
        _isUpdatingState = false;
      }
    }
  }

  void _onSearchChanged(String query) {
    if (!_isUpdatingState && mounted) {
      _isUpdatingState = true;
      try {
        setState(() {
          _searchQuery = query;
          _groupNotificationsByDate();
        });
      } finally {
        _isUpdatingState = false;
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationFilterSheetWidget(
        selectedTypes: _selectedFilters,
        onFiltersChanged: (filters) {
          // Delay state update to ensure sheet is fully dismissed
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isUpdatingState) {
              _isUpdatingState = true;
              try {
                setState(() {
                  _selectedFilters = filters;
                  _groupNotificationsByDate();
                });
              } finally {
                _isUpdatingState = false;
              }
            }
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
    setState(() {
      notification['isRead'] = true;
      _groupNotificationsByDate();
    });

    // Call API to mark as read
    try {
      // Handle both int and string ID types
      final dynamic idValue = notification['id'];
      final int notificationId;

      if (idValue is int) {
        notificationId = idValue;
      } else if (idValue is String) {
        notificationId = int.parse(idValue);
      } else {
        throw Exception('Invalid notification ID type: ${idValue.runtimeType}');
      }

      await _apiService
          .markNotificationsAsRead(notificationIds: [notificationId]);
    } catch (e) {}

    await _saveNotifications();
    HapticFeedback.lightImpact();
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
    // Call API to mark as deleted/read
    try {
      final notificationId = int.parse(notification['id']);
      await _apiService
          .markNotificationsAsRead(notificationIds: [notificationId]);
    } catch (e) {}

    setState(() {
      _allNotifications.removeWhere((n) => n['id'] == notification['id']);
      _groupNotificationsByDate();
    });
    HapticFeedback.mediumImpact();

    await _saveNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          duration: const Duration(seconds: 3),
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
    await _loadNotificationsFromAPI();
  }

  @override
  Widget build(BuildContext context) {
    final hasNotifications = _groupedNotifications.isNotEmpty;

    // Show loading indicator
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                onPressed: _loadCachedNotifications,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: CustomIconWidget(
              iconName: _isSearchVisible ? 'close' : 'search',
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
          if (hasNotifications && _unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.1),
                        labelStyle:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
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
                      selectedColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      labelStyle:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
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

  String _normalizeType(dynamic rawType) {
    if (rawType == null) return 'general';
    final t = rawType.toString().toLowerCase().replaceAll('-', '_');
    switch (t) {
      case 'bus_approaching':
      case 'busapproaching':
      case 'bus_coming':
      case 'approaching':
        return 'bus_approaching';
      case 'pickup_confirmed':
      case 'pickupcomplete':
      case 'pickup_done':
      case 'picked_up':
        return 'pickup_confirmed';
      case 'dropoff_complete':
      case 'dropoffconfirmed':
      case 'dropped_off':
        return 'dropoff_complete';
      case 'route_change':
      case 'routechanged':
      case 'route_update':
        return 'route_change';
      case 'emergency':
      case 'alert_emergency':
      case 'critical':
        return 'emergency';
      case 'major_delay':
      case 'delay_major':
      case 'delayed':
        return 'major_delay';
      default:
        return 'general';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notificationsSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
