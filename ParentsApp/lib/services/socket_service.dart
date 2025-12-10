import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../config/api_config.dart';
import '../config/location_config.dart';
import '../models/bus_location_model.dart';

/// Socket.IO Service for Real-time Updates
///
/// Handles WebSocket connections to the Node.js Socket.IO relay service
/// for receiving real-time bus location updates, trip notifications, etc.
///
/// Architecture:
/// 1. Driver sends location via HTTP POST to Django
/// 2. Django publishes to Redis pub/sub
/// 3. Node.js Socket.IO service subscribes to Redis
/// 4. This service connects to Node.js via WebSocket
/// 5. Parents receive real-time updates through streams
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  int? _subscribedBusId;
  int _reconnectionAttempts = 0;

  // Stream controllers for different event types
  final _tripStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _locationUpdateController = StreamController<BusLocation>.broadcast();
  final _tripCompletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<LocationConnectionState>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get tripStartedStream => _tripStartedController.stream;
  Stream<BusLocation> get locationUpdateStream => _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get tripCompletedStream => _tripCompletedController.stream;
  Stream<LocationConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;
  int? get subscribedBusId => _subscribedBusId;

  /// Connect to Socket.IO server
  ///
  /// Establishes WebSocket connection with JWT authentication.
  /// Automatically handles reconnection and event listeners.
  Future<void> connect() async {
    if (_isConnected && _socket != null) {
      if (LocationConfig.enableSocketLogging) {
        print('Socket already connected');
      }
      return;
    }

    try {
      _connectionStateController.add(LocationConnectionState.connecting);

      // Get access token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken == null) {
        print('ERROR: No access token found. Cannot connect to Socket.IO');
        _connectionStateController.add(LocationConnectionState.error);
        _errorController.add('Authentication required');
        return;
      }

      if (LocationConfig.enableSocketLogging) {
        print('Connecting to Socket.IO server at ${ApiConfig.socketServerUrl}');
      }

      _socket = IO.io(
        ApiConfig.socketServerUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setAuth({
          'token': accessToken, // Send without Bearer prefix
          'userType': 'parent',  // Specify user type
        })
            .setReconnectionDelay(LocationConfig.socketReconnectionDelay.inMilliseconds)
            .setReconnectionAttempts(LocationConfig.maxReconnectionAttempts)
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();

    } catch (e) {
      print('ERROR: Failed to connect to Socket.IO: $e');
      _isConnected = false;
      _connectionStateController.add(LocationConnectionState.error);
      _errorController.add('Connection failed: ${e.toString()}');
    }
  }

  /// Setup all Socket.IO event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      if (LocationConfig.enableSocketLogging) {
        print('✅ Socket.IO connected successfully');
      }
      _isConnected = true;
      _reconnectionAttempts = 0;
      _connectionStateController.add(LocationConnectionState.connected);

      // Re-subscribe to bus if we were subscribed before disconnect
      if (_subscribedBusId != null) {
        subscribeToBus(_subscribedBusId!);
      }
    });

    _socket!.onDisconnect((_) {
      if (LocationConfig.enableSocketLogging) {
        print('❌ Socket.IO disconnected');
      }
      _isConnected = false;
      _connectionStateController.add(LocationConnectionState.disconnected);
    });

    _socket!.onConnectError((error) {
      print('❌ Socket.IO connection error: $error');
      _isConnected = false;
      _reconnectionAttempts++;
      _connectionStateController.add(LocationConnectionState.error);
      _errorController.add('Connection error: ${error.toString()}');
    });

    _socket!.onError((error) {
      print('❌ Socket.IO error: $error');
      _errorController.add('Socket error: ${error.toString()}');
    });

    _socket!.onReconnect((attempt) {
      if (LocationConfig.enableSocketLogging) {
        print('🔄 Socket.IO reconnecting (attempt $attempt)...');
      }
      _connectionStateController.add(LocationConnectionState.connecting);
    });

    _socket!.onReconnectError((error) {
      print('❌ Socket.IO reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      print('❌ Socket.IO reconnection failed');
      _connectionStateController.add(LocationConnectionState.error);
      _errorController.add('Failed to reconnect after maximum attempts');
    });

    // Real-time location updates
    _socket!.on('location_update', (data) {
      try {
        final location = BusLocation.fromJson(Map<String, dynamic>.from(data));
        _locationUpdateController.add(location);
      } catch (e) {
        if (LocationConfig.enableSocketLogging) {
          print('ERROR: Failed to parse location update: $e');
        }
        _errorController.add('Failed to parse location update');
      }
    });

    // Subscription confirmation
    _socket!.on('subscribed', (data) {
      if (LocationConfig.enableSocketLogging) {
        print('✅ Subscription confirmed: $data');
      }
    });

    // Subscription error
    _socket!.on('error', (data) {
      print('❌ Subscription error: $data');
      _errorController.add(data['message'] ?? 'Unknown error');
    });

    // Legacy events (for backward compatibility)
    _socket!.on('trip_started', (data) {
      if (LocationConfig.enableSocketLogging) {
        print('🚌 Trip started event: $data');
      }
      _tripStartedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('trip_completed', (data) {
      if (LocationConfig.enableSocketLogging) {
        print('🏁 Trip completed event: $data');
      }
      _tripCompletedController.add(Map<String, dynamic>.from(data));
    });
  }

  /// Subscribe to real-time location updates for a specific bus
  ///
  /// This joins the Socket.IO room for the given bus ID.
  /// All location updates for this bus will be received through locationUpdateStream.
  void subscribeToBus(int busId) {
    if (!_isConnected || _socket == null) {
      print('WARNING: Cannot subscribe - Socket not connected');
      _errorController.add('Not connected to server');
      return;
    }

    // Already subscribed to this bus
    if (_subscribedBusId == busId) {
      print('ℹ️ Already subscribed to bus $busId, skipping duplicate subscription');
      return;
    }

    print('📡 Subscribing to bus $busId location updates');

    // Unsubscribe from previous bus if subscribed
    if (_subscribedBusId != null && _subscribedBusId != busId) {
      unsubscribeFromBus(_subscribedBusId!);
    }

    _subscribedBusId = busId;
    _socket!.emit('subscribe_bus', {'busId': busId});
  }

  /// Unsubscribe from a bus's location updates
  void unsubscribeFromBus(int busId) {
    if (!_isConnected || _socket == null) {
      return;
    }

    if (LocationConfig.enableSocketLogging) {
      print('📡 Unsubscribing from bus $busId');
    }

    _socket!.emit('unsubscribe_bus', {'busId': busId});

    if (_subscribedBusId == busId) {
      _subscribedBusId = null;
    }
  }

  /// Ping the server to check connection health
  void ping() {
    if (_socket != null && _isConnected) {
      _socket!.emit('ping');
    }
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      if (LocationConfig.enableSocketLogging) {
        print('🔌 Disconnecting from Socket.IO');
      }

      // Unsubscribe from current bus before disconnecting
      if (_subscribedBusId != null) {
        unsubscribeFromBus(_subscribedBusId!);
      }

      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _subscribedBusId = null;
      _connectionStateController.add(LocationConnectionState.disconnected);
    }
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _tripStartedController.close();
    _locationUpdateController.close();
    _tripCompletedController.close();
    _connectionStateController.close();
    _errorController.close();
  }
}
