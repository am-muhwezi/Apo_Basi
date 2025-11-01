import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Socket.IO service for real-time driver location tracking
///
/// This service manages:
/// - WebSocket connection to Node.js server
/// - Emitting driver location updates every 10 meters
/// - Room-based communication (bus-specific rooms)
/// - Automatic reconnection on connection loss
class SocketService {
  IO.Socket? socket;
  StreamSubscription<Position>? _locationStream;
  bool _isConnected = false;
  String? _currentBusId;

  // Singleton pattern - only one instance throughout the app
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  /// Initialize Socket.IO connection to server
  ///
  /// Parameters:
  /// - [serverUrl]: Node.js server URL (e.g., 'http://192.168.100.43:4000')
  /// - [driverId]: Driver's unique ID from backend
  /// - [busId]: Bus ID assigned to this driver
  ///
  /// Example:
  /// ```dart
  /// socketService.initializeSocket(
  ///   serverUrl: 'http://192.168.100.43:4000',
  ///   driverId: 123,
  ///   busId: 456,
  /// );
  /// ```
  void initializeSocket({
    required String serverUrl,
    required int driverId,
    required String busId,
  }) {
    _currentBusId = busId;

    // Create socket connection with options
    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])        // Use WebSocket (faster than polling)
        .enableAutoConnect()                 // Connect automatically
        .enableReconnection()                // Auto-reconnect on disconnect
        .setReconnectionDelay(1000)          // Wait 1 second before reconnect
        .setReconnectionDelayMax(5000)       // Max 5 seconds between retries
        .setReconnectionAttempts(10)         // Try 10 times before giving up
        .setExtraHeaders({
          'driver_id': driverId.toString(),
          'bus_id': busId,
        })
        .build(),
    );

    _setupSocketListeners();

    // Connect to server
    socket?.connect();
  }

  /// Setup Socket.IO event listeners
  void _setupSocketListeners() {
    // Connection successful
    socket?.on('connect', (_) {
      print('✅ Socket.IO: Connected to server (ID: ${socket?.id})');
      _isConnected = true;

      // Join specific bus room for targeted broadcasts
      if (_currentBusId != null) {
        socket?.emit('join_bus_room', _currentBusId);
        print('🚌 Socket.IO: Joined bus room: $_currentBusId');
      }
    });

    // Connection error
    socket?.on('connect_error', (error) {
      print('⚠️ Socket.IO: Connection error: $error');
      _isConnected = false;
    });

    // Connection timeout
    socket?.on('connect_timeout', (_) {
      print('⏱️ Socket.IO: Connection timeout');
      _isConnected = false;
    });

    // Disconnected from server
    socket?.on('disconnect', (reason) {
      print('❌ Socket.IO: Disconnected (reason: $reason)');
      _isConnected = false;
    });

    // Reconnecting
    socket?.on('reconnect', (attempt) {
      print('🔄 Socket.IO: Reconnected (attempt: $attempt)');
      _isConnected = true;

      // Rejoin bus room after reconnection
      if (_currentBusId != null) {
        socket?.emit('join_bus_room', _currentBusId);
      }
    });

    // Reconnecting attempt
    socket?.on('reconnect_attempt', (attempt) {
      print('🔄 Socket.IO: Reconnecting... (attempt: $attempt)');
    });

    // Failed to reconnect
    socket?.on('reconnect_failed', (_) {
      print('❌ Socket.IO: Failed to reconnect after all attempts');
      _isConnected = false;
    });
  }

  /// Emit driver's current location to server
  ///
  /// Data format sent to server:
  /// ```json
  /// {
  ///   "busId": "bus_123",
  ///   "latitude": 0.3476,
  ///   "longitude": 32.5825,
  ///   "accuracy": 15.0,
  ///   "speed": 12.5,
  ///   "heading": 45.0,
  ///   "altitude": 1200.0,
  ///   "timestamp": "2025-10-30T10:30:15.000Z"
  /// }
  /// ```
  void emitDriverLocation(Position position) {
    if (!_isConnected) {
      print('⚠️ Socket.IO: Cannot emit location - Not connected to server');
      return;
    }

    if (_currentBusId == null) {
      print('⚠️ Socket.IO: Cannot emit location - No bus ID set');
      return;
    }

    // Prepare location data
    final locationData = {
      'busId': _currentBusId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'heading': position.heading,
      'altitude': position.altitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Emit to server using room-based event
    socket?.emit('driver_location_room', locationData);

    print('📍 Socket.IO: Location emitted → Lat: ${position.latitude.toStringAsFixed(4)}, '
          'Lng: ${position.longitude.toStringAsFixed(4)}, '
          'Accuracy: ±${position.accuracy.toInt()}m, '
          'Speed: ${position.speed.toStringAsFixed(1)} m/s');
  }

  /// Start real-time location tracking and emission
  ///
  /// This creates a stream that:
  /// - Updates every 10 meters of movement
  /// - Uses high GPS accuracy
  /// - Automatically emits to Socket.IO server
  ///
  /// Make sure location permissions are granted before calling this!
  void startLocationTracking() {
    if (_locationStream != null) {
      print('⚠️ Location tracking already active');
      return;
    }

    print('🎯 Starting location tracking (updates every 10m)...');

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,  // Only emit when driver moves 10+ meters
      ),
    ).listen(
      (Position position) {
        // Emit location to Socket.IO server
        emitDriverLocation(position);
      },
      onError: (error) {
        print('❌ Location tracking error: $error');
      },
      onDone: () {
        print('✅ Location tracking stream closed');
      },
    );
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _locationStream?.cancel();
    _locationStream = null;
    print('🛑 Location tracking stopped');
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    stopLocationTracking();
    socket?.disconnect();
    socket?.dispose();
    _isConnected = false;
    print('🔌 Socket.IO: Disconnected and disposed');
  }

  /// Check if socket is connected
  bool get isConnected => _isConnected;

  /// Get current bus ID
  String? get currentBusId => _currentBusId;

  /// Get socket ID (assigned by server)
  String? get socketId => socket?.id;
}
