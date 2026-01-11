/// Real-time Location Tracking Configuration
///
/// Centralized configuration for location tracking, Socket.IO connections,
/// and real-time bus monitoring features.

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationConfig {
  // ============================================================================
  // Map Bounds Configuration
  // ============================================================================

  /// Map bounds - limits the visible area to Limuru Road, 2 Rivers area
  /// Southwest corner: South of 2 Rivers Mall
  /// Northeast corner: North along Limuru Road
  static final LatLngBounds mapBounds = LatLngBounds(
    LatLng(-1.2500, 36.7500), // Southwest (South of working area)
    LatLng(-1.1700, 36.8500), // Northeast (North of working area)
  );

  // ============================================================================
  // Socket.IO Configuration
  // ============================================================================

  /// Socket.IO Server URL (defaults to value in api_config.dart)
  /// This should point to the Node.js Socket.IO relay service
  static const String socketUrl =
      String.fromEnvironment('SOCKET_URL', defaultValue: '');

  /// Socket.IO connection timeout
  static const Duration socketConnectionTimeout = Duration(seconds: 10);

  /// Socket.IO reconnection delay
  static const Duration socketReconnectionDelay = Duration(seconds: 2);

  /// Maximum reconnection attempts before giving up
  static const int maxReconnectionAttempts = 5;

  // ============================================================================
  // Location Update Timing
  // ============================================================================

  /// How often drivers send location updates to backend (HTTP POST)
  /// Balance between accuracy and battery/data usage
  /// Recommended: 5-10 seconds for active tracking
  static const Duration locationUpdateInterval = Duration(seconds: 5);

  /// Minimum distance (in meters) before sending location update
  /// Helps save battery and data when bus is stationary
  /// Set to 0 to disable distance filtering
  static const double locationDistanceFilter = 10.0; // meters

  /// How often to check for location changes in background
  /// This is different from update interval - this is how often we READ location
  static const Duration backgroundLocationCheckInterval = Duration(seconds: 3);

  // ============================================================================
  // Staleness Thresholds
  // ============================================================================

  /// Time threshold for marking location as "stale" (warning state)
  /// Parent UI will show yellow warning if no update received in this time
  static const Duration staleThreshold = Duration(seconds: 30);

  /// Time threshold for marking location as "offline" (error state)
  /// Parent UI will show red error if no update received in this time
  static const Duration offlineThreshold = Duration(minutes: 5);

  /// How often to update the "last updated X seconds ago" timestamp in UI
  static const Duration timestampUpdateInterval = Duration(seconds: 1);

  // ============================================================================
  // Map Configuration
  // ============================================================================

  /// Default map zoom level when showing bus location
  static const double defaultMapZoom = 15.0;

  /// Map zoom level when tracking multiple buses (admin view)
  static const double multipleBusesZoom = 12.0;

  /// Animation duration for map marker movements
  static const Duration markerAnimationDuration = Duration(milliseconds: 500);

  /// Whether to animate marker movement (vs instant jump)
  static const bool animateMarkerMovement = true;

  // ============================================================================
  // Location Permissions
  // ============================================================================

  /// Location accuracy for tracking
  /// Options: lowest, low, medium, high, best, bestForNavigation
  static const String locationAccuracy = 'high';

  /// Whether to request background location permission on Android
  static const bool requestBackgroundLocation = true;

  /// Whether to show rationale before requesting permissions
  static const bool showPermissionRationale = true;

  // ============================================================================
  // Data Persistence
  // ============================================================================

  /// Whether to cache failed location updates for retry
  static const bool cacheFailedUpdates = true;

  /// Maximum number of failed updates to cache
  static const int maxCachedUpdates = 50;

  /// How long to keep cached location data (for offline viewing)
  static const Duration cacheExpiry = Duration(hours: 24);

  // ============================================================================
  // Battery Optimization
  // ============================================================================

  /// Whether to enable battery-saving mode when battery is low
  static const bool enableBatterySaving = true;

  /// Battery level threshold (0-100) to trigger battery-saving mode
  static const int batterySavingThreshold = 20;

  /// Location update interval when in battery-saving mode
  static const Duration batterySavingUpdateInterval = Duration(seconds: 15);

  // ============================================================================
  // Development/Debug
  // ============================================================================

  /// Enable detailed logging for location tracking
  static const bool enableLocationLogging = false;

  /// Enable Socket.IO event logging
  static const bool enableSocketLogging = true;

  /// Show debug overlay on map (connection status, update count, etc.)
  static const bool showDebugOverlay = false;

  /// Whether to use mock location data in development
  static const bool useMockLocation = false;

  // ============================================================================
  // Error Handling
  // ============================================================================

  /// Number of retries for failed location updates
  static const int locationUpdateRetries = 3;

  /// Delay between retries
  static const Duration retryDelay = Duration(seconds: 2);

  /// Whether to show toast notifications for location errors
  static const bool showLocationErrorToasts = true;

  // ============================================================================
  // Validation
  // ============================================================================

  /// Validate all configuration values
  static bool validateConfig() {
    if (locationUpdateInterval.inSeconds < 1) {
      return false;
    }

    if (locationDistanceFilter < 0) {
      return false;
    }

    if (staleThreshold.inSeconds < 1) {
      return false;
    }

    if (offlineThreshold <= staleThreshold) {
      return false;
    }

    return true;
  }

  /// Print configuration summary (for debugging)
  static void printConfigSummary() {
  }
}
