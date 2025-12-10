import 'package:flutter/services.dart';
import 'dart:async';

/// Service to communicate with native Android foreground service
/// for continuous background location tracking
///
/// This service provides a bridge to the Android Foreground Service
/// which runs independently of the Flutter app lifecycle.
///
/// Key features:
/// - Continues tracking when app is minimized, locked, or swiped away
/// - Shows persistent notification to user
/// - Survives app being killed by system
/// - Sends location updates to DRF backend
class NativeLocationService {
  static const MethodChannel _channel =
      MethodChannel('com.apobasi.driver/location_service');

  static final NativeLocationService _instance =
      NativeLocationService._internal();
  factory NativeLocationService() => _instance;
  NativeLocationService._internal();

  bool _isTracking = false;
  final _statusController = StreamController<LocationServiceStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  /// Stream of location service status changes
  Stream<LocationServiceStatus> get statusStream => _statusController.stream;

  /// Stream of error messages
  Stream<String> get errorStream => _errorController.stream;

  /// Whether the service is currently tracking
  bool get isTracking => _isTracking;

  /// Start the native foreground service for location tracking
  ///
  /// This will continue tracking even when app is:
  /// - Minimized
  /// - Locked
  /// - Swiped away
  /// - Screen is off
  ///
  /// Returns true if service started successfully
  Future<bool> startLocationTracking({
    required String token,
    required int busId,
    required String apiUrl,
  }) async {
    try {
      // Validate inputs
      if (token.isEmpty) {
        throw Exception('Auth token is required');
      }
      if (busId <= 0) {
        throw Exception('Valid bus ID is required');
      }
      if (apiUrl.isEmpty) {
        throw Exception('API URL is required');
      }

      final result = await _channel.invokeMethod('startLocationService', {
        'token': token,
        'busId': busId,
        'apiUrl': apiUrl,
      });

      final success = result == true;

      if (success) {
        _isTracking = true;
        _statusController.add(LocationServiceStatus.started);
      } else {
        _statusController.add(LocationServiceStatus.stopped);
      }

      return success;
    } on PlatformException catch (e) {
      final errorMsg = 'Failed to start location service: ${e.code} - ${e.message}';
      _errorController.add(errorMsg);
      _statusController.add(LocationServiceStatus.error);
      _isTracking = false;
      return false;
    } catch (e) {
      final errorMsg = 'Unexpected error starting location service: $e';
      _errorController.add(errorMsg);
      _statusController.add(LocationServiceStatus.error);
      _isTracking = false;
      return false;
    }
  }

  /// Stop the native foreground service
  ///
  /// Returns true if service stopped successfully
  Future<bool> stopLocationTracking() async {
    try {
      final result = await _channel.invokeMethod('stopLocationService');
      final success = result == true;

      if (success) {
        _isTracking = false;
        _statusController.add(LocationServiceStatus.stopped);
      }

      return success;
    } on PlatformException catch (e) {
      final errorMsg = 'Failed to stop location service: ${e.code} - ${e.message}';
      _errorController.add(errorMsg);
      return false;
    } catch (e) {
      final errorMsg = 'Unexpected error stopping location service: $e';
      _errorController.add(errorMsg);
      return false;
    }
  }

  /// Check if location permissions are granted
  ///
  /// Returns true if all required permissions are granted
  Future<bool> checkLocationPermission() async {
    try {
      final result = await _channel.invokeMethod('checkLocationPermission');
      return result == true;
    } on PlatformException catch (e) {
      final errorMsg = 'Error checking location permission: ${e.code} - ${e.message}';
      _errorController.add(errorMsg);
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Request location permissions
  ///
  /// This will show the native Android permission dialog
  Future<void> requestLocationPermission() async {
    try {
      await _channel.invokeMethod('requestLocationPermission');
    } on PlatformException catch (e) {
      final errorMsg = 'Error requesting location permission: ${e.code} - ${e.message}';
      _errorController.add(errorMsg);
    } catch (e) {
      // Silently fail
    }
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
    _errorController.close();
  }
}

/// Status of the location tracking service
enum LocationServiceStatus {
  /// Service is running and tracking location
  started,

  /// Service is stopped
  stopped,

  /// Service encountered an error
  error,
}
