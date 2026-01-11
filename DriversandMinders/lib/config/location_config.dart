/// Real-time Location Tracking Configuration for Drivers
///
/// Centralized configuration for driver location sharing features.

class LocationConfig {
  // ============================================================================
  // Location Update Timing
  // ============================================================================

  /// How often drivers send location updates to backend (HTTP POST)
  /// Balance between accuracy and battery/data usage
  /// Recommended: 3-5 seconds for active tracking
  static const Duration locationUpdateInterval = Duration(seconds: 3);

  /// Minimum distance (in meters) before sending location update
  /// Helps save battery and data when bus is stationary
  /// Optimized: Bus must move ≥20m before update is sent
  /// This prevents excessive updates when bus is stopped/slow traffic
  /// Set to 0 to disable distance filtering
  static const double locationDistanceFilter = 20.0; // meters

  /// How often to check for location changes in background
  /// This is different from update interval - this is how often we READ location
  static const Duration backgroundLocationCheckInterval = Duration(seconds: 3);

  // ============================================================================
  // Background Service Configuration
  // ============================================================================

  /// Whether to run location tracking as foreground service on Android
  /// Foreground services show persistent notification but are less likely to be killed
  static const bool useForegroundService = true;

  /// Notification title for foreground service
  static const String foregroundServiceTitle = 'ApoBasi - Sharing Location';

  /// Notification body for foreground service
  static const String foregroundServiceBody =
      'Your bus location is being shared with parents';

  /// Notification icon for foreground service (must exist in Android res/)
  static const String foregroundServiceIcon = 'ic_launcher';

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
  // Location Permissions
  // ============================================================================

  /// Location accuracy for tracking
  /// Options: lowest, low, medium, high, best, bestForNavigation
  static const String locationAccuracy = 'high';

  /// Whether to request background location permission on Android
  static const bool requestBackgroundLocation = true;

  /// Whether to request "always" location permission on iOS
  static const bool requestAlwaysLocationIOS = true;

  // ============================================================================
  // Data Persistence
  // ============================================================================

  /// Whether to cache failed location updates for retry
  static const bool cacheFailedUpdates = true;

  /// Maximum number of failed updates to cache
  static const int maxCachedUpdates = 50;

  /// How long to keep cached location updates before discarding
  static const Duration cachedUpdateExpiry = Duration(hours: 1);

  // ============================================================================
  // Battery Optimization
  // ============================================================================

  /// Whether to enable battery-saving mode when battery is low
  static const bool enableBatterySaving = true;

  /// Battery level threshold (0-100) to trigger battery-saving mode
  static const int batterySavingThreshold = 20;

  /// Location update interval when in battery-saving mode
  /// Less frequent checks when battery is low
  static const Duration batterySavingUpdateInterval = Duration(seconds: 10);

  /// Distance filter when in battery-saving mode
  /// Require more movement before sending update to save battery
  static const double batterySavingDistanceFilter = 30.0; // meters

  // ============================================================================
  // Development/Debug
  // ============================================================================

  /// Enable detailed logging for location tracking
  static const bool enableLocationLogging = false;

  /// Show debug overlay on driver screen (update count, last sent time, etc.)
  static const bool showDebugOverlay = false;

  /// Whether to use mock location data in development
  static const bool useMockLocation = false;

  /// Mock location coordinates (used if useMockLocation is true)
  static const double mockLatitude = 9.0820;
  static const double mockLongitude = 7.5340;

  /// Whether to simulate movement in mock mode
  static const bool simulateMovement = false;

  // ============================================================================
  // Error Handling
  // ============================================================================

  /// Number of retries for failed location updates
  static const int locationUpdateRetries = 3;

  /// Delay between retries
  static const Duration retryDelay = Duration(seconds: 2);

  /// Whether to show toast notifications for location errors
  static const bool showLocationErrorToasts = true;

  /// Whether to continue tracking even if update fails
  /// If false, tracking stops after max retries fail
  static const bool continueTrackingOnError = true;

  // ============================================================================
  // Safety and Validation
  // ============================================================================

  /// Maximum allowed speed (km/h) before treating as invalid GPS reading
  /// Helps filter GPS glitches
  static const double maxAllowedSpeed = 200.0;

  /// Minimum accuracy (meters) required to accept GPS reading
  /// Higher values = more accurate but slower to get fix
  static const double minimumAccuracy = 50.0;

  /// Whether to validate location before sending
  static const bool validateLocation = true;

  // ============================================================================
  // Configuration Helpers
  // ============================================================================

  /// Validate all configuration values
  static bool validateConfig() {
    if (locationUpdateInterval.inSeconds < 1) {
      return false;
    }

    if (locationDistanceFilter < 0) {
      return false;
    }

    if (batterySavingUpdateInterval <= locationUpdateInterval) {
      return false;
    }

    if (minimumAccuracy <= 0) {
      return false;
    }

    return true;
  }

  /// Print configuration summary (for debugging)
  static void printConfigSummary() {}
}
