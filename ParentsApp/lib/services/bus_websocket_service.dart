import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/location_config.dart';
import '../models/bus_location_model.dart';
import 'notification_service.dart';

/// WebSocket Service for Real-time Bus Location Tracking
///
/// Connects to Django Channels WebSocket endpoints for real-time updates.
/// Supports JWT authentication and automatic reconnection.
///
/// Architecture:
/// 1. Parents authenticate with JWT token
/// 2. Connect to Django Channels WebSocket endpoint
/// 3. Receive real-time location updates for subscribed buses
/// 4. Automatic reconnection on disconnect
class BusWebSocketService {
  static final BusWebSocketService _instance = BusWebSocketService._internal();
  factory BusWebSocketService() => _instance;
  BusWebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  int? _subscribedBusId;
  int _reconnectionAttempts = 0;
  Timer? _reconnectTimer;
  String? _accessToken;
  // Set true before calling sink.close() so _handleDisconnect knows not to
  // schedule an automatic reconnect (the caller will reconnect manually).
  bool _intentionalDisconnect = false;

  // Stream controllers for different event types
  final _locationUpdateController = StreamController<BusLocation>.broadcast();
  final _connectionStateController =
      StreamController<LocationConnectionState>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  // Trip lifecycle events: trip_started / trip_ended
  final _tripEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  // Server-computed ETAs: childId (String) → seconds (int)
  final _etaUpdateController =
      StreamController<Map<String, int>>.broadcast();

  // Public streams
  Stream<BusLocation> get locationUpdateStream =>
      _locationUpdateController.stream;
  Stream<LocationConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Map<String, dynamic>> get tripEventStream =>
      _tripEventController.stream;
  /// ETA updates broadcast from the server (Mapbox Matrix, 60 s throttle).
  /// Keys are child IDs as strings; values are ETA in seconds.
  Stream<Map<String, int>> get etaUpdateStream => _etaUpdateController.stream;

  bool get isConnected => _isConnected;
  int? get subscribedBusId => _subscribedBusId;

  // Last trip_state received from the server. Persists in the singleton so
  // child_detail_screen can apply it immediately on re-entry instead of
  // waiting for the next WS trip_state message.
  Map<String, dynamic>? _lastTripState;
  Map<String, dynamic>? get lastTripState => _lastTripState;

  // Cached names used when firing system notifications on trip events.
  // bus_number comes from location_update messages; child name is set by caller.
  String? _lastKnownBusNumber;
  String? _lastKnownChildName;

  /// Call this after subscribeToBus() with the child's display name so that
  /// trip event notifications can show e.g. "Yahweh Alpha Pickup Trip Started".
  void setChildName(String name) {
    _lastKnownChildName = name;
  }

  /// Connect to WebSocket server (initialize service)
  ///
  /// This method initializes the service and prepares for connection.
  /// Call subscribeToBus() to actually connect to a specific bus.
  Future<void> connect() async {
    // Get access token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');

    if (_accessToken == null) {
      _connectionStateController.add(LocationConnectionState.error);
      _errorController.add('Authentication required');
      return;
    }

    if (LocationConfig.enableSocketLogging) {}
  }

  /// Subscribe to a specific bus for real-time location updates
  ///
  /// Establishes WebSocket connection with JWT authentication.
  /// Automatically handles reconnection.
  void subscribeToBus(int busId) {
    if (_isConnected && _subscribedBusId == busId) {
      if (LocationConfig.enableSocketLogging) {}
      return;
    }

    // Disconnect from previous bus if connected
    if (_isConnected && _subscribedBusId != null && _subscribedBusId != busId) {
      unsubscribeFromBus(_subscribedBusId!);
    }

    _connectToBusWebSocket(busId);
  }

  /// Unsubscribe from a bus's location updates
  void unsubscribeFromBus(int busId) {
    if (_subscribedBusId == busId) {
      disconnect();
    }
  }

  /// Internal method to connect to WebSocket for a specific bus
  Future<void> _connectToBusWebSocket(int busId) async {
    if (_accessToken == null) {
      // Try to get token again
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');

      if (_accessToken == null) {
        _connectionStateController.add(LocationConnectionState.error);
        _errorController.add('Authentication required');
        return;
      }
    }

    try {
      _connectionStateController.add(LocationConnectionState.connecting);

      _subscribedBusId = busId;

      // Build WebSocket URL with bus ID and token
      final wsUrl =
          '${_getWebSocketBaseUrl()}/ws/bus/$busId/?token=$_accessToken';

      if (LocationConfig.enableSocketLogging) {}

      // Create WebSocket channel
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectionAttempts = 0;
    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(LocationConnectionState.error);
      _errorController.add('Connection failed: ${e.toString()}');
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final messageType = data['type'];
      debugPrint('[WS] received: $messageType | ${message.toString().length > 200 ? message.toString().substring(0, 200) : message}');

      if (messageType == 'connected') {
        if (LocationConfig.enableSocketLogging) {}
        _reconnectionAttempts = 0; // Reset on successful connection
        _connectionStateController.add(LocationConnectionState.connected);
        // No need to request_current_location — the server immediately sends
        // trip_state which includes bus_latitude/longitude as the GPS seed.
      } else if (messageType == 'location_update') {
        // Parse location update
        final location = BusLocation(
          busId: data['bus_id'] as int,
          busNumber: data['bus_number'] ?? '',
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          snappedLatitude: (data['snapped_latitude'] as num?)?.toDouble(),
          snappedLongitude: (data['snapped_longitude'] as num?)?.toDouble(),
          speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
          heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
          bearing: (data['bearing'] as num?)?.toDouble(),
          isActive: data['is_active'] ?? true,
          timestamp: DateTime.parse(data['timestamp']),
        );

        if (LocationConfig.enableSocketLogging) {}

        // Cache bus number so trip event notifications have something to show
        if (location.busNumber.isNotEmpty) {
          _lastKnownBusNumber = location.busNumber;
        }

        _locationUpdateController.add(location);
      } else if (messageType == 'trip_state' ||
          messageType == 'trip_started' ||
          messageType == 'trip_ended') {
        final event = Map<String, dynamic>.from(data);
        // Keep a snapshot of the latest trip state so screens can restore
        // immediately on re-entry without waiting for the next WS message.
        if (messageType == 'trip_state') {
          _lastTripState = event;
        } else if (messageType == 'trip_ended') {
          _lastTripState = {'type': 'trip_state', 'has_active_trip': false};
          // Fire system notification so parents get an alert on the phone header
          final tripType = data['trip_type'] as String? ?? 'pickup';
          final busNumber = _lastKnownBusNumber ?? 'your bus';
          final childName = _lastKnownChildName ?? 'Your child';
          NotificationService().showTripCompletedNotification(
            childName: childName,
            busNumber: busNumber,
            tripType: tripType,
            busId: _subscribedBusId ?? 0,
          );
        } else if (messageType == 'trip_started') {
          // Merge trip_started fields into a trip_state-shaped snapshot so
          // the screen can re-apply GPS seed coordinates on re-entry.
          _lastTripState = {
            'type': 'trip_state',
            'has_active_trip': true,
            'trip_id': event['trip_id'],
            'trip_type': event['trip_type'],
            'scheduled_time': event['scheduled_time'],
            'bus_latitude': event['bus_latitude'],
            'bus_longitude': event['bus_longitude'],
            'bus_speed': event['bus_speed'],
            'bus_heading': event['bus_heading'],
          };
          // Fire system notification so parents get an alert on the phone header
          final tripType = data['trip_type'] as String? ?? 'pickup';
          final busNumber = _lastKnownBusNumber ?? 'your bus';
          final childName = _lastKnownChildName ?? 'Your child';
          NotificationService().showTripStartNotification(
            childName: childName,
            busNumber: busNumber,
            tripType: tripType,
            busId: _subscribedBusId ?? 0,
          );
        }
        _tripEventController.add(event);
      } else if (messageType == 'eta_update') {
        final rawEtas = data['etas'] as Map<String, dynamic>? ?? {};
        final etas = rawEtas.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );
        _etaUpdateController.add(etas);
      } else if (messageType == 'error') {
        _errorController.add(data['message']);
      }
    } catch (e) {
      if (LocationConfig.enableSocketLogging) {}
      _errorController.add('Failed to parse message');
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    _isConnected = false;
    _connectionStateController.add(LocationConnectionState.error);
    _errorController.add('Connection error: ${error.toString()}');
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    if (LocationConfig.enableSocketLogging) {}
    _isConnected = false;
    _connectionStateController.add(LocationConnectionState.disconnected);
    // If disconnect() was called deliberately (e.g. TripWatcher forcing a
    // reconnect), skip the auto-reconnect.  The caller will call
    // subscribeToBus() immediately after.
    if (_intentionalDisconnect) {
      _intentionalDisconnect = false;
      return;
    }
    _scheduleReconnect();
  }

  /// Schedule automatic reconnection.
  ///
  /// Uses quick retries (2 s) for the first [maxReconnectionAttempts] attempts,
  /// then switches to a slow 30-second retry loop so the client never
  /// permanently gives up waiting for the driver to start a trip.
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already scheduled
    }

    _reconnectionAttempts++;

    // After exhausting quick retries, keep trying every 30 s indefinitely.
    final delay = _reconnectionAttempts > LocationConfig.maxReconnectionAttempts
        ? const Duration(seconds: 30)
        : LocationConfig.socketReconnectionDelay;

    if (LocationConfig.enableSocketLogging) {}

    _reconnectTimer = Timer(delay, () {
      // Only reconnect if still disconnected — guards against the race where
      // the TripWatcher (or the caller) already reconnected while this timer
      // was pending.
      if (_subscribedBusId != null && !_isConnected) {
        _connectToBusWebSocket(_subscribedBusId!);
      }
    });
  }

  /// Request current location from server
  void requestCurrentLocation() {
    if (!_isConnected || _channel == null) {
      return;
    }

    _channel!.sink.add(json.encode({
      'type': 'request_current_location',
    }));
  }

  /// Request current trip state from server (heartbeat / sync)
  void requestTripState() {
    if (!_isConnected || _channel == null) {
      return;
    }

    _channel!.sink.add(json.encode({
      'type': 'request_trip_state',
    }));
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }

    if (_channel != null) {
      if (LocationConfig.enableSocketLogging) {}

      _intentionalDisconnect = true; // Suppress auto-reconnect in _handleDisconnect
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      _subscribedBusId = null;
      _reconnectionAttempts = 0;
      _connectionStateController.add(LocationConnectionState.disconnected);
    }
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _locationUpdateController.close();
    _connectionStateController.close();
    _errorController.close();
    _tripEventController.close();
    _etaUpdateController.close();
  }

  /// Get WebSocket base URL from API config
  String _getWebSocketBaseUrl() {
    // Strip trailing slashes before converting scheme to avoid double-slash
    // in the final URL (e.g. wss://api.apobasi.com//ws/bus/1/).
    final baseUrl = ApiConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
    return 'ws://$baseUrl';
  }
}
