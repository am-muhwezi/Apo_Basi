import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity status
///
/// Provides real-time connectivity monitoring and callbacks
/// for connection state changes to trigger data refresh
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = false;
  bool _wasOffline = false;

  /// Callback triggered when connection is restored
  Function()? onConnectionRestored;

  /// Callback triggered when connection is lost
  Function()? onConnectionLost;

  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _updateConnectivityStatus(results);
      },
    );
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectivityStatus(results);
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
    }
  }

  /// Update connectivity status based on results
  Future<void> _updateConnectivityStatus(List<ConnectivityResult> results) async {
    final wasConnected = _isConnected;

    // Check if any result indicates connectivity
    _isConnected = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    // Connection restored
    if (_isConnected && !wasConnected) {
      _wasOffline = false;
      print('Connection restored');
      if (onConnectionRestored != null) {
        onConnectionRestored!();
      }
    }

    // Connection lost
    if (!_isConnected && wasConnected) {
      _wasOffline = true;
      print('Connection lost');
      if (onConnectionLost != null) {
        onConnectionLost!();
      }
    }
  }

  /// Check if we were offline (useful for showing "back online" messages)
  bool get wasOffline => _wasOffline;

  /// Reset offline flag
  void resetOfflineFlag() {
    _wasOffline = false;
  }

  /// Manually check connectivity (for pull-to-refresh scenarios)
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
