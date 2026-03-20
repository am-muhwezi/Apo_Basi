import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';

/// WebSocket Service for Driver Location Tracking
///
/// Connects to Django Channels WebSocket endpoints for real-time location updates.
/// Supports JWT authentication and automatic reconnection.
///
/// Features:
/// - Sends driver location updates to Django Channels
/// - Receives acknowledgments and error messages
/// - Automatic reconnection on disconnect
/// - JWT authentication
class BusWebSocketService {
  static final BusWebSocketService _instance = BusWebSocketService._internal();
  factory BusWebSocketService() => _instance;
  BusWebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  int? _connectedBusId;
  int _reconnectionAttempts = 0;
  Timer? _reconnectTimer;
  String? _accessToken;

  // Stream controllers
  final _connectionStateController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  // ETA updates pushed by the server's Mapbox Matrix computation.
  // Map of student_id (string) → eta_seconds (int).
  final _etaUpdateController = StreamController<Map<String, int>>.broadcast();
  // Road-snapped position echoed back by the server after processing each GPS packet.
  final _snappedPositionController =
      StreamController<Map<String, double>>.broadcast();

  // Public streams
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<Map<String, int>> get etaUpdateStream => _etaUpdateController.stream;
  /// Emits {lat, lng} with road-snapped coordinates from the server.
  Stream<Map<String, double>> get snappedPositionStream =>
      _snappedPositionController.stream;

  bool get isConnected => _isConnected;
  int? get connectedBusId => _connectedBusId;

  /// Connect to WebSocket server for a specific bus
  ///
  /// Parameters:
  /// - [busId]: Bus ID assigned to this driver
  /// - [accessToken]: JWT access token for authentication
  Future<void> connectToBus({
    required int busId,
    required String accessToken,
  }) async {
    if (_isConnected && _connectedBusId == busId) {
      return;
    }

    // Disconnect from previous bus if connected
    if (_isConnected && _connectedBusId != null && _connectedBusId != busId) {
      disconnect();
    }

    try {
      _accessToken = accessToken;
      _connectedBusId = busId;

      // Build WebSocket URL with bus ID and token
      final wsUrl = _buildWebSocketUrl(busId, accessToken);


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
      _connectionStateController.add(true);
    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(false);
      _errorController.add('Connection failed: ${e.toString()}');
      _scheduleReconnect();
    }
  }

  /// Send location update to server
  ///
  /// This is called by the driver location service to send real-time updates.
  void sendLocationUpdate(Position position) {
    if (!_isConnected || _channel == null) {
      return;
    }

    try {
      final locationData = {
        'type': 'location_update',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(json.encode(locationData));
    } catch (e) {
      _errorController.add('Failed to send location');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final messageType = data['type'];

      if (messageType == 'connected') {
        _isConnected = true;
        _connectionStateController.add(true);
      } else if (messageType == 'error') {
        _errorController.add(data['message']);
      } else if (messageType == 'location_update') {
        // Server echoes back the road-snapped coordinates.
        final sLat = (data['snapped_latitude'] as num?)?.toDouble();
        final sLng = (data['snapped_longitude'] as num?)?.toDouble();
        if (sLat != null && sLng != null) {
          _snappedPositionController.add({'lat': sLat, 'lng': sLng});
        }
      } else if (messageType == 'eta_update') {
        final rawEtas = data['etas'] as Map?;
        if (rawEtas != null) {
          _etaUpdateController.add(
            rawEtas.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
          );
        }
      }
    } catch (e) {
      _errorController.add('Failed to parse message');
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    _isConnected = false;
    _connectionStateController.add(false);
    _errorController.add('Connection error: ${error.toString()}');
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    _isConnected = false;
    _connectionStateController.add(false);
    _scheduleReconnect();
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    const maxAttempts = 10;

    if (_reconnectionAttempts >= maxAttempts) {
      _errorController.add('Failed to reconnect after maximum attempts');
      return;
    }

    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Already scheduled
    }

    _reconnectionAttempts++;
    const delay = Duration(seconds: 3);

    _reconnectTimer = Timer(delay, () {
      if (_connectedBusId != null && _accessToken != null) {
        connectToBus(
          busId: _connectedBusId!,
          accessToken: _accessToken!,
        );
      }
    });
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }

    if (_channel != null) {

      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      _connectedBusId = null;
      _reconnectionAttempts = 0;
      _connectionStateController.add(false);
    }
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _errorController.close();
    _etaUpdateController.close();
    _snappedPositionController.close();
  }

  /// Build WebSocket URL from base URL
  String _buildWebSocketUrl(int busId, String token) {
    // Convert HTTP URL to WebSocket URL
    final baseUrl = ApiConfig.apiBaseUrl;
    String wsBaseUrl;

    if (baseUrl.startsWith('https://')) {
      wsBaseUrl = baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      wsBaseUrl = baseUrl.replaceFirst('http://', 'ws://');
    } else {
      wsBaseUrl = 'ws://$baseUrl';
    }

    return '$wsBaseUrl/ws/bus/$busId/?token=$token';
  }
}
