/// API Configuration for DriversandMinders App
///
/// Centralized configuration for all API keys, URLs, and service endpoints

class ApiConfig {
  // ============================================================================
  // Backend API Configuration
  // ============================================================================

  /// Django Backend API Base URL
  /// DEVELOPMENT: Use WiFi IP for testing on physical device
  /// Android emulator: 'http://10.0.2.2:8000'
  /// iOS simulator: 'http://localhost:8000'
  /// Production: 'https://yourdomain.com' or 'http://YOUR_VPS_IP'
  static const String apiBaseUrl = 'http://192.168.100.65:8000';

  /// Socket.IO Server URL for real-time updates
  /// Must be accessible from mobile devices (not localhost!)
  static const String socketServerUrl = 'http://192.168.100.65:3001';
  // ============================================================================
  // Mapbox Configuration
  // ============================================================================

  /// Mapbox Access Token
  /// Get your token from: https://account.mapbox.com/access-tokens/
  /// Free tier includes: 50,000 map loads per month
  static const String mapboxAccessToken =
      'pk.eyJ1IjoieWFod2Voc2RlbGlnaHQiLCJhIjoiY21pZXAzNHpyMDR1bDNlcjFjYjhndzZ3MSJ9.OzjPk7KtUsKiuPTKUnTBSg';

  /// Mapbox Style ID
  /// Available styles: streets-v12, outdoors-v12, light-v11, dark-v11,
  /// satellite-v9, satellite-streets-v12
  static const String mapboxStyleId = 'mapbox/streets-v12';

  /// Get the Mapbox tile URL template for flutter_map
  static String getMapboxTileUrl() {
    return 'https://api.mapbox.com/styles/v1/$mapboxStyleId/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken';
  }

  /// Get Mapbox tile URL for a specific style
  static String getMapboxTileUrlWithStyle(String styleId) {
    return 'https://api.mapbox.com/styles/v1/$styleId/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken';
  }

  /// Available Mapbox styles
  static const Map<String, String> mapboxStyles = {
    'streets': 'mapbox/streets-v12',
    'outdoors': 'mapbox/outdoors-v12',
    'light': 'mapbox/light-v11',
    'dark': 'mapbox/dark-v11',
    'satellite': 'mapbox/satellite-v9',
    'satellite-streets': 'mapbox/satellite-streets-v12',
  };

  // ============================================================================
  // API Endpoints
  // ============================================================================

  /// Auth endpoints
  static const String driverLoginEndpoint = '/api/drivers/login/';
  static const String busminderLoginEndpoint = '/api/busminders/login/';
  static const String refreshTokenEndpoint = '/api/token/refresh/';

  /// Driver endpoints
  static const String driversEndpoint = '/api/drivers/';
  static String driverDetailEndpoint(int id) => '/api/drivers/$id/';

  /// Busminder endpoints
  static const String busmindersEndpoint = '/api/busminders/';
  static String busminderDetailEndpoint(int id) => '/api/busminders/$id/';

  /// Trips endpoints
  static const String tripsEndpoint = '/api/trips/';
  static String tripDetailEndpoint(int id) => '/api/trips/$id/';
  static String tripStartEndpoint(int id) => '/api/trips/$id/start/';
  static String tripCompleteEndpoint(int id) => '/api/trips/$id/complete/';
  static String tripUpdateLocationEndpoint(int id) =>
      '/api/trips/$id/update-location/';

  /// Attendance endpoints
  static String tripAttendanceEndpoint(int tripId) =>
      '/api/trips/$tripId/attendance/';
  static String markAttendanceEndpoint(int tripId, int childId) =>
      '/api/trips/$tripId/attendance/$childId/mark/';

  // ============================================================================
  // Configuration Helpers
  // ============================================================================

  /// Check if running in development mode
  static bool isDevelopment() {
    return apiBaseUrl.contains('localhost') ||
        apiBaseUrl.contains('127.0.0.1') ||
        apiBaseUrl.contains('192.168.');
  }

  /// Get user-friendly environment name
  static String getEnvironmentName() {
    if (isDevelopment()) return 'Development';
    return 'Production';
  }

  /// Validate all required configurations
  static bool validateConfig() {
    if (mapboxAccessToken.isEmpty) {
      print('WARNING: Mapbox token not configured');
      return false;
    }

    if (apiBaseUrl.isEmpty) {
      print('ERROR: API Base URL not configured');
      return false;
    }

    if (socketServerUrl.isEmpty) {
      print('ERROR: Socket.IO Server URL not configured');
      return false;
    }

    return true;
  }

  /// Print configuration summary (for debugging)
  static void printConfigSummary() {
    print('=== DriversandMinders API Configuration ===');
    print('Environment: ${getEnvironmentName()}');
    print('API Base URL: $apiBaseUrl');
    print('Socket Server: $socketServerUrl');
    print('Mapbox Configured: ${mapboxAccessToken.isNotEmpty}');
    print('Mapbox Style: $mapboxStyleId');
    print('===========================================');
  }
}
