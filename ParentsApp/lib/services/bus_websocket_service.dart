import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/location_config.dart';
import '../models/bus_location_model.dart';

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

  // Stream controllers for different event types
  final _locationUpdateController = StreamController<BusLocation>.broadcast();
  final _connectionStateController =
      StreamController<LocationConnectionState>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<BusLocation> get locationUpdateStream =>
      _locationUpdateController.stream;
  Stream<LocationConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;
  int? get subscribedBusId => _subscribedBusId;

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

      if (messageType == 'connected') {
        if (LocationConfig.enableSocketLogging) {}
        _connectionStateController.add(LocationConnectionState.connected);

        // Request current location
        requestCurrentLocation();
      } else if (messageType == 'location_update') {
        // Parse location update
        final location = BusLocation(
          busId: data['bus_id'] as int,
          busNumber: data['bus_number'] ?? '', // Bus number from server
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
          heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
          isActive: data['is_active'] ?? true,
          timestamp: DateTime.parse(data['timestamp']),
        );

        if (LocationConfig.enableSocketLogging) {}

        _locationUpdateController.add(location);
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
    _scheduleReconnect();
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    if (_reconnectionAttempts >= LocationConfig.maxReconnectionAttempts) {
      _connectionStateController.add(LocationConnectionState.error);
      _errorController.add('Failed to reconnect after maximum attempts');
      return;
    }

    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already scheduled
    }

    _reconnectionAttempts++;
    final delay = LocationConfig.socketReconnectionDelay;

    if (LocationConfig.enableSocketLogging) {}

    _reconnectTimer = Timer(delay, () {
      if (_subscribedBusId != null) {
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

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }

    if (_channel != null) {
      if (LocationConfig.enableSocketLogging) {}

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
}
