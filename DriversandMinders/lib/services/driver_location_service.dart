import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/location_config.dart';

/// Driver Location Service
///
/// Handles background location tracking for drivers and sends real-time
/// location updates to the backend.
///
/// Architecture Flow:
/// 1. Driver enables location sharing
/// 2. Service tracks location every 3-5 seconds
/// 3. HTTP POST to Django /api/buses/push-location/
/// 4. Django publishes to Redis pub/sub
/// 5. Node.js Socket.IO service relays to subscribed parents
///
/// Features:
/// - Background location tracking
/// - Retry queue for failed requests
/// - Distance filtering to save battery
/// - Battery-saving mode when low battery
/// - Configurable update intervals
class DriverLocationService {
  static final DriverLocationService _instance =
      DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  // Service state
  bool _isTracking = false;
  Timer? _locationTimer;
  Position? _lastSentPosition;
  DateTime? _lastUpdateTime;
  int? _currentBusId;
  int? _currentTripId;

  // Dio HTTP client for location HTTP endpoints
  late Dio _dio;

  // Retry queue for failed updates
  final List<Map<String, dynamic>> _retryQueue = [];
  Timer? _retryTimer;
  Timer? _tripUpdateTimer;

  // Stream controllers
  final _trackingStateController = StreamController<bool>.broadcast();
  final _locationUpdateController = StreamController<Position>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _statsController = StreamController<LocationStats>.broadcast();

  // Stats tracking
  int _totalUpdatesSent = 0;
  int _failedUpdates = 0;
  int _queuedUpdates = 0;

  // Public streams
  Stream<bool> get trackingStateStream => _trackingStateController.stream;
  Stream<Position> get locationUpdateStream => _locationUpdateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<LocationStats> get statsStream => _statsController.stream;

  // Getters
  bool get isTracking => _isTracking;
  Position? get lastPosition => _lastSentPosition;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  int get queuedUpdatesCount => _retryQueue.length;

  /// Initialize the service
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    // Add authentication interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
    ));

    // Load saved bus ID
    final prefs = await SharedPreferences.getInstance();
    _currentBusId = prefs.getInt('current_bus_id');
    _currentTripId = prefs.getInt('current_trip_id');

    if (LocationConfig.enableLocationLogging) {}
  }

  /// Set the current bus ID for tracking
  Future<void> setBusId(int busId) async {
    _currentBusId = busId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_bus_id', busId);

    if (LocationConfig.enableLocationLogging) {}
  }

  /// Start location tracking
  Future<bool> startTracking() async {
    if (_isTracking) {
      if (LocationConfig.enableLocationLogging) {}
      return true;
    }

    if (_currentBusId == null) {
      _errorController.add('No bus assigned. Cannot start tracking.');
      return false;
    }

    // Check location permissions
    bool hasPermission = await _checkPermissions();
    if (!hasPermission) {
      _errorController.add('Location permission denied');
      return false;
    }

    // Check location service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorController.add('Location services disabled');
      return false;
    }

    _isTracking = true;
    _trackingStateController.add(true);

    if (LocationConfig.enableLocationLogging) {}

    // Start periodic location updates
    _startPeriodicUpdates();

    // Start trip-level updates if a trip is active
    _startTripUpdateTimer();

    // Start retry timer for failed updates
    if (LocationConfig.cacheFailedUpdates) {
      _startRetryTimer();
    }

    // NOTE: Background service disabled due to Android foreground service issues
    // Location tracking will continue in foreground mode
    // TODO: Implement proper background service with WorkManager or native Android code
    // final service = FlutterBackgroundService();
    // await service.startService();

    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', true);

    return true;
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    _trackingStateController.add(false);

    // Cancel timers
    _locationTimer?.cancel();
    _locationTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _tripUpdateTimer?.cancel();
    _tripUpdateTimer = null;

    if (LocationConfig.enableLocationLogging) {}

    // Save tracking state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', false);
  }

  /// Set the current trip ID for trip-level updates
  Future<void> setTripId(int? tripId) async {
    _currentTripId = tripId;
    final prefs = await SharedPreferences.getInstance();
    if (tripId != null) {
      await prefs.setInt('current_trip_id', tripId);
    }
  }

  /// Toggle tracking on/off
  Future<bool> toggleTracking() async {
    if (_isTracking) {
      await stopTracking();
      return false;
    } else {
      return await startTracking();
    }
  }

  /// Check and request location permissions
  Future<bool> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Request background location on Android
    if (LocationConfig.requestBackgroundLocation) {
      // Background permission handled by platform-specific code
      if (LocationConfig.enableLocationLogging) {}
    }

    return true;
  }

  /// Start periodic location updates
  void _startPeriodicUpdates() {
    // Get update interval
    Duration interval = LocationConfig.locationUpdateInterval;

    // Adjust interval for battery saving mode
    if (LocationConfig.enableBatterySaving) {
      // Note: Battery level checking requires battery_plus package
      // For now, just use configured interval
      // TODO: Add battery_plus package and implement battery monitoring
    }

    _locationTimer = Timer.periodic(interval, (_) async {
      await _sendLocationUpdate();
    });

    // Send initial update immediately
    _sendLocationUpdate();
  }

  /// Send current location to backend
  Future<void> _sendLocationUpdate() async {
    if (!_isTracking || _currentBusId == null) return;

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: _getLocationAccuracy(),
          distanceFilter: LocationConfig.locationDistanceFilter.toInt(),
        ),
      );

      // Check distance filter
      if (_shouldFilterByDistance(position)) {
        if (LocationConfig.enableLocationLogging) {}
        return;
      }

      // Always send via HTTP to the bus push-location endpoint
      final payload = {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
      };

      final response = await _dio.post(
        '/api/buses/push-location/',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _lastSentPosition = position;
        _lastUpdateTime = DateTime.now();
        _totalUpdatesSent++;
        _locationUpdateController.add(position);
        _updateStats();

        if (LocationConfig.enableLocationLogging) {}

        // Process retry queue on successful update
        if (_retryQueue.isNotEmpty) {
          _processRetryQueue();
        }
      } else {
        throw Exception('Invalid response: ${response.statusCode}');
      }
    } catch (e) {
      _handleLocationUpdateError(e);
    }
  }

  /// Handle location update errors
  void _handleLocationUpdateError(dynamic error) {
    if (LocationConfig.enableLocationLogging) {}

    _failedUpdates++;

    // Add to retry queue if enabled (only if we have a valid position)
    if (LocationConfig.cacheFailedUpdates &&
        _retryQueue.length < LocationConfig.maxCachedUpdates &&
        _lastSentPosition != null) {
      try {
        final payload = {
          'lat': _lastSentPosition!.latitude,
          'lng': _lastSentPosition!.longitude,
          'speed': _lastSentPosition!.speed,
          'heading': _lastSentPosition!.heading,
          'retry_count': 0,
        };
        _retryQueue.add(payload);
        _queuedUpdates++;
      } catch (e) {
        if (LocationConfig.enableLocationLogging) {}
      }
    }

    _updateStats();

    // Only show error toast for persistent failures
    if (_failedUpdates > 3 && LocationConfig.showLocationErrorToasts) {
      _errorController.add('Failed to send location updates. Will retry...');
    }
  }

  /// Check if location should be filtered by distance
  bool _shouldFilterByDistance(Position position) {
    if (_lastSentPosition == null) return false;
    if (LocationConfig.locationDistanceFilter <= 0) return false;

    double distance = Geolocator.distanceBetween(
      _lastSentPosition!.latitude,
      _lastSentPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    return distance < LocationConfig.locationDistanceFilter;
  }

  /// Get location accuracy based on configuration
  LocationAccuracy _getLocationAccuracy() {
    switch (LocationConfig.locationAccuracy) {
      case 'lowest':
        return LocationAccuracy.lowest;
      case 'low':
        return LocationAccuracy.low;
      case 'medium':
        return LocationAccuracy.medium;
      case 'high':
        return LocationAccuracy.high;
      case 'best':
        return LocationAccuracy.best;
      case 'bestForNavigation':
        return LocationAccuracy.bestForNavigation;
      default:
        return LocationAccuracy.high;
    }
  }

  /// Start retry timer for failed updates
  void _startRetryTimer() {
    _retryTimer = Timer.periodic(LocationConfig.retryDelay, (_) {
      if (_retryQueue.isNotEmpty) {
        _processRetryQueue();
      }
    });
  }

  /// Start periodic HTTP updates to the trip update-location endpoint
  void _startTripUpdateTimer() {
    if (_tripUpdateTimer != null) return;

    _tripUpdateTimer = Timer.periodic(
      LocationConfig.locationUpdateInterval,
      (_) async {
        if (!_isTracking || _currentTripId == null) return;
        if (_lastSentPosition == null) return;

        try {
          await _dio.post(
            '/api/trips/${_currentTripId!}/update-location/',
            data: {
              'latitude': _lastSentPosition!.latitude,
              'longitude': _lastSentPosition!.longitude,
              'speed': _lastSentPosition!.speed,
              'heading': _lastSentPosition!.heading,
            },
          );
        } catch (_) {
          // Silent failure; bus-level updates still continue
        }
      },
    );
  }

  /// Process retry queue
  Future<void> _processRetryQueue() async {
    if (_retryQueue.isEmpty || !_isTracking) return;

    // Process up to 5 items at a time
    final itemsToRetry = _retryQueue.take(5).toList();

    for (var payload in itemsToRetry) {
      try {
        final response = await _dio.post(
          '/api/buses/push-location/',
          data: payload,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          _retryQueue.remove(payload);
          _queuedUpdates--;

          if (LocationConfig.enableLocationLogging) {}
        } else {
          // Increment retry count
          payload['retry_count'] = (payload['retry_count'] ?? 0) + 1;

          // Remove if max retries reached
          if (payload['retry_count'] > LocationConfig.locationUpdateRetries) {
            _retryQueue.remove(payload);
            _queuedUpdates--;
            if (LocationConfig.enableLocationLogging) {}
          }
        }
      } catch (e) {
        // Keep in queue for next retry
        if (LocationConfig.enableLocationLogging) {}
      }
    }

    _updateStats();
  }

  /// Update and broadcast stats
  void _updateStats() {
    final stats = LocationStats(
      totalUpdatesSent: _totalUpdatesSent,
      failedUpdates: _failedUpdates,
      queuedUpdates: _queuedUpdates,
      lastUpdateTime: _lastUpdateTime,
      isTracking: _isTracking,
    );
    _statsController.add(stats);
  }

  /// Clear retry queue
  void clearRetryQueue() {
    _retryQueue.clear();
    _queuedUpdates = 0;
    _updateStats();
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'is_tracking': _isTracking,
      'bus_id': _currentBusId,
      'total_updates': _totalUpdatesSent,
      'failed_updates': _failedUpdates,
      'queued_updates': _queuedUpdates,
      'last_update': _lastUpdateTime?.toIso8601String(),
      'last_position': _lastSentPosition != null
          ? {
              'lat': _lastSentPosition!.latitude,
              'lng': _lastSentPosition!.longitude,
            }
          : null,
    };
  }

  /// Dispose resources
  void dispose() {
    _locationTimer?.cancel();
    _retryTimer?.cancel();
    _trackingStateController.close();
    _locationUpdateController.close();
    _errorController.close();
    _statsController.close();
  }
}

/// Location tracking statistics
class LocationStats {
  final int totalUpdatesSent;
  final int failedUpdates;
  final int queuedUpdates;
  final DateTime? lastUpdateTime;
  final bool isTracking;

  const LocationStats({
    required this.totalUpdatesSent,
    required this.failedUpdates,
    required this.queuedUpdates,
    this.lastUpdateTime,
    required this.isTracking,
  });

  double get successRate {
    if (totalUpdatesSent == 0) return 0.0;
    return ((totalUpdatesSent - failedUpdates) / totalUpdatesSent) * 100;
  }

  String get lastUpdateText {
    if (lastUpdateTime == null) return 'Never';
    final diff = DateTime.now().difference(lastUpdateTime!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
