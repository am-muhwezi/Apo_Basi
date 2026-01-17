import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'notification_service.dart';

/// WebSocket Service for Real-time Parent Notifications
///
/// Connects to Django Channels WebSocket endpoint for real-time notifications.
/// Supports JWT authentication and automatic reconnection.
///
/// Notification Types:
/// - Trip notifications (trip_started, trip_ended)
/// - Attendance notifications (pickup_confirmed, dropoff_complete)
/// - Route change notifications
/// - Emergency alerts
/// - Delay notifications
/// - Bus proximity alerts
class ParentNotificationsService {
  static final ParentNotificationsService _instance =
      ParentNotificationsService._internal();
  factory ParentNotificationsService() => _instance;
  ParentNotificationsService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  int _reconnectionAttempts = 0;
  Timer? _reconnectTimer;
  String? _accessToken;
  bool _hasTriedTokenRefresh = false;

  // Stream controllers for different notification types
  final _tripNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _attendanceNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _routeChangeNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _emergencyNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _delayNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _proximityNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _allNotificationsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get tripNotificationStream =>
      _tripNotificationController.stream;
  Stream<Map<String, dynamic>> get attendanceNotificationStream =>
      _attendanceNotificationController.stream;
  Stream<Map<String, dynamic>> get routeChangeNotificationStream =>
      _routeChangeNotificationController.stream;
  Stream<Map<String, dynamic>> get emergencyNotificationStream =>
      _emergencyNotificationController.stream;
  Stream<Map<String, dynamic>> get delayNotificationStream =>
      _delayNotificationController.stream;
  Stream<Map<String, dynamic>> get proximityNotificationStream =>
      _proximityNotificationController.stream;
  Stream<Map<String, dynamic>> get allNotificationsStream =>
      _allNotificationsController.stream;
  Stream<String> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;

  /// Connect to notifications WebSocket
  Future<void> connect() async {
    // Get access token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');

    if (_accessToken == null || _accessToken!.isEmpty) {
      _connectionStateController.add('error');
      _errorController.add('Authentication required - please log in');
      return;
    }

    _connectToWebSocket();
  }

  /// Internal method to establish WebSocket connection
  Future<void> _connectToWebSocket() async {
    try {
      _connectionStateController.add('connecting');

      // Build WebSocket URL with token authentication
      final wsUrl =                                                                                                 
      '${_getWebSocketBaseUrl()}/ws/notifications/parent/?token=$_accessToken';    

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) => _handleError(error),
        onDone: _handleDisconnect,
      );

      _isConnected = true;
      _reconnectionAttempts = 0;
      _hasTriedTokenRefresh = false;
      _connectionStateController.add('connected');
    } catch (e) {
      await _handleError(e);
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      final messageType = data['type'] as String?;

      if (messageType == null) return;

      switch (messageType) {
        case 'connected':
          break;

        case 'trip_notification':
          _handleTripNotification(data);
          break;

        case 'attendance_notification':
          _handleAttendanceNotification(data);
          break;

        case 'route_change_notification':
          _handleRouteChangeNotification(data);
          break;

        case 'emergency_notification':
          _handleEmergencyNotification(data);
          break;

        case 'delay_notification':
          _handleDelayNotification(data);
          break;

        case 'proximity_notification':
          _handleProximityNotification(data);
          break;

        case 'error':
          _errorController.add(data['message'] ?? 'Unknown error');
          break;

        default:
      }
    } catch (e) {}
  }

  String _resolveChildName(Map<String, dynamic> data) {
    final rawFieldName = (data['child_name'] ??
            data['childName'] ??
            data['student_name'] ??
            data['name'])
        ?.toString()
        .trim();

    if (rawFieldName != null && rawFieldName.isNotEmpty) {
      return rawFieldName;
    }

    final String title = (data['title'] ?? '').toString();
    if (title.isNotEmpty) {
      const patterns = [
        ' Pickup Trip Started',
        ' Reached School Safely',
        ' Picked Up',
        ' Dropped Off',
        ' Trip Completed',
      ];

      for (final pattern in patterns) {
        if (title.contains(pattern)) {
          final namePart = title.split(pattern).first.trim();
          if (namePart.isNotEmpty) {
            return namePart;
          }
        }
      }
    }

    return 'Your child';
  }

  /// Handle trip notifications
  void _handleTripNotification(Map<String, dynamic> data) {
    _tripNotificationController.add(data);
    _allNotificationsController.add(data);
    _saveNotificationToCache(data);

    // Show local notification
    final notificationType = data['notification_type'];
    final childName = _resolveChildName(data);
    if (notificationType == 'trip_started') {
      NotificationService().showTripStartNotification(
        childName: childName,
        busNumber: data['bus_number'] ?? 'Unknown',
        tripType: data['trip_type'] ?? 'Unknown',
        busId: data['bus_id'] ?? 0,
      );
    } else if (notificationType == 'trip_ended') {
      NotificationService().showTripCompletedNotification(
        childName: childName,
        busNumber: data['bus_number'] ?? 'Unknown',
        tripType: data['trip_type'] ?? 'Unknown',
        busId: data['bus_id'] ?? 0,
      );
    }
  }

  /// Handle attendance notifications
  void _handleAttendanceNotification(Map<String, dynamic> data) {
    _attendanceNotificationController.add(data);
    _allNotificationsController.add(data);
    _saveNotificationToCache(data);

    // Show local notification
    final notificationType = data['notification_type'];
    final childName = _resolveChildName(data);
    final busNumber = data['bus_number'] ?? 'Unknown';

    if (notificationType == 'pickup_confirmed') {
      NotificationService().showPickupNotification(
        childName: childName,
        busNumber: busNumber,
      );
    } else if (notificationType == 'dropoff_complete') {
      NotificationService().showDropoffNotification(
        childName: childName,
        busNumber: busNumber,
      );
    }
  }

  /// Handle route change notifications
  void _handleRouteChangeNotification(Map<String, dynamic> data) {
    _routeChangeNotificationController.add(data);
    _allNotificationsController.add(data);
    _saveNotificationToCache(data);
  }

  /// Handle emergency notifications
  void _handleEmergencyNotification(Map<String, dynamic> data) {
    _emergencyNotificationController.add(data);
    _allNotificationsController.add(data);
    _saveNotificationToCache(data);
  }

  /// Handle delay notifications
  void _handleDelayNotification(Map<String, dynamic> data) {
    _delayNotificationController.add(data);
    _allNotificationsController.add(data);
    _saveNotificationToCache(data);
  }

  /// Handle proximity notifications
  void _handleProximityNotification(Map<String, dynamic> data) {
    _proximityNotificationController.add(data);
    _allNotificationsController.add(data);
    _saveNotificationToCache(data);
  }

  /// Save notification to local cache
  Future<void> _saveNotificationToCache(
      Map<String, dynamic> notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNotifications =
          prefs.getStringList('cached_notifications') ?? [];

      // Convert notification to JSON string
      final notificationData = {
        'id': notification['id'],
        'type': notification['notification_type'],
        'title': notification['title'],
        'message': notification['message'],
        'fullMessage': notification['full_message'],
        'timestamp': notification['timestamp'],
        'isRead': false,
        'expanded': false,
        // Add any extra data
        ...notification,
      };

      cachedNotifications.insert(0, json.encode(notificationData));

      // Keep only the latest 100 notifications
      if (cachedNotifications.length > 100) {
        cachedNotifications.removeRange(100, cachedNotifications.length);
      }

      await prefs.setStringList('cached_notifications', cachedNotifications);
    } catch (e) {}
  }

  /// Handle WebSocket errors
  Future<void> _handleError(dynamic error) async {
    _isConnected = false;
    _connectionStateController.add('error');

    final errorStr = error.toString().toLowerCase();

    // Detect network-level connection refused errors
    final isConnectionRefused = errorStr.contains('connection refused') ||
        errorStr.contains('os error');

    // Check if it's likely an authentication error (expired/invalid token)
    final looksLikeAuthError = !isConnectionRefused &&
        (errorStr.contains('401') ||
            errorStr.contains('4001') ||
            errorStr.contains('unauthorized') ||
            errorStr.contains('authentication') ||
            (errorStr.contains('token') && errorStr.contains('expired')) ||
            errorStr.contains('not upgraded to websocket'));

    if (looksLikeAuthError) {
      // Try a single token refresh using the stored refresh token
      if (!_hasTriedTokenRefresh) {
        _hasTriedTokenRefresh = true;
        final refreshed = await _refreshTokenAndReconnect();
        if (!refreshed) {
          _errorController.add('Session expired - please log in again');
        }
      } else {
        _errorController.add('Session expired - please log in again');
      }
      // For auth issues we don't use the normal reconnection loop
      return;
    }

    _errorController.add(error.toString());
    _attemptReconnection();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    _isConnected = false;
    _connectionStateController.add('disconnected');
    _attemptReconnection();
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnection() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already attempting reconnection
    }

    _reconnectionAttempts++;
    if (_reconnectionAttempts > 5) {
      _errorController.add('Failed to reconnect after 5 attempts');
      return;
    }

    // Exponential backoff: 2^n seconds
    final delay = Duration(seconds: 1 << _reconnectionAttempts);

    _reconnectTimer = Timer(delay, () {
      _connectToWebSocket();
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (!_isConnected) return;

    try {
      final message = json.encode({
        'type': 'mark_as_read',
        'notification_id': notificationId,
      });

      _channel?.sink.add(message);
    } catch (e) {}
  }

  /// Request unread notification count
  Future<void> requestUnreadCount() async {
    if (!_isConnected) return;

    try {
      final message = json.encode({
        'type': 'get_unread_count',
      });

      _channel?.sink.add(message);
    } catch (e) {}
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _hasTriedTokenRefresh = false;
    _connectionStateController.add('disconnected');
  }

  /// Refresh JWT access token using stored refresh token and reconnect
  Future<bool> _refreshTokenAndReconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post(
        ApiConfig.refreshTokenEndpoint,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 && response.data['access'] != null) {
        final newAccessToken = response.data['access'] as String;
        _accessToken = newAccessToken;
        await prefs.setString('access_token', newAccessToken);

        if (response.data['refresh'] != null) {
          await prefs.setString(
              'refresh_token', response.data['refresh'] as String);
        }

        // Reconnect WebSocket with new token
        await _connectToWebSocket();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get WebSocket base URL from API config                                                                  
    String _getWebSocketBaseUrl() {                                                                             
      // Convert HTTP URL to WebSocket URL                                                                      
      final baseUrl = ApiConfig.apiBaseUrl;                                                                     
      if (baseUrl.startsWith('https://')) {                                                                     
        return baseUrl.replaceFirst('https://', 'wss://');                                                      
      } else if (baseUrl.startsWith('http://')) {                                                               
        return baseUrl.replaceFirst('http://', 'ws://');                                                        
      }                                                                                                         
      return 'ws://$baseUrl';                                                                                   
    }               

  /// Dispose all resources
  void dispose() {
    disconnect();
    _tripNotificationController.close();
    _attendanceNotificationController.close();
    _routeChangeNotificationController.close();
    _emergencyNotificationController.close();
    _delayNotificationController.close();
    _proximityNotificationController.close();
    _allNotificationsController.close();
    _connectionStateController.close();
    _errorController.close();
  }
}
