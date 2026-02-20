import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration
///
/// Centralized configuration for all API keys, URLs, and service endpoints
/// used in the Parents App.

class ApiConfig {
  // ============================================================================
  // Backend API Configuration
  // ============================================================================

  /// Django Backend API Base URL
  /// DEVELOPMENT: Use WiFi IP for testing on physical device
  /// Android emulator: 'http://10.0.2.2:8000'
  /// iOS simulator: 'http://localhost:8000'
  /// Production: 'https://yourdomain.com' or 'http://YOUR_VPS_IP'
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  /// Socket.IO Server URL for real-time updates
  /// Must be accessible from mobile devices (not localhost!)
  static String get socketServerUrl => dotenv.env['SOCKET_SERVER_URL'] ?? '';
  // ============================================================================
  // Mapbox Configuration
  // ============================================================================

  /// Mapbox Access Token
  /// Get your token from: https://account.mapbox.com/access-tokens/
  /// Free tier includes: 50,000 map loads per month

  static String get mapboxAccessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  /// Mapbox Style ID (e.g. 'd-ampire/cmltlzid4000o01qu8ze2hrr2')
  static String get mapboxStyleId =>
      dotenv.env['MAPBOX_STYLE_ID'] ?? 'mapbox/streets-v12';

  /// Get the Mapbox style URI for the native SDK
  static String getMapboxStyleUri() {
    return 'mapbox://styles/$mapboxStyleId';
  }

  // ============================================================================
  // API Endpoints
  // ============================================================================

  /// Auth endpoints
  static const String loginEndpoint = '/api/parents/login/';
  static const String refreshTokenEndpoint = '/api/token/refresh/';

  /// Parents endpoints
  static const String parentsEndpoint = '/api/parents/';
  static String parentDetailEndpoint(int id) => '/api/parents/$id/';
  static String parentChildrenEndpoint(int id) => '/api/parents/$id/children/';

  /// Children endpoints
  static const String childrenEndpoint = '/api/children/';
  static String childDetailEndpoint(int id) => '/api/children/$id/';

  /// Trips endpoints
  static const String tripsEndpoint = '/api/trips/';
  static String tripDetailEndpoint(int id) => '/api/trips/$id/';
  static String tripLocationEndpoint(int id) => '/api/trips/$id/location/';

  /// Notifications endpoints
  static const String notificationsEndpoint = '/api/notifications/';
  static String markNotificationReadEndpoint(int id) =>
      '/api/notifications/$id/mark-read/';

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
      return false;
    }
    if (apiBaseUrl.isEmpty) {
      return false;
    }
    if (socketServerUrl.isEmpty) {
      return false;
    }
    return true;
  }

  /// Print configuration summary (for debugging)
  static void printConfigSummary() {
  }
}
