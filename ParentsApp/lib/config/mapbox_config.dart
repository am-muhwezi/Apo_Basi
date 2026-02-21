/// Mapbox Configuration (Backward Compatibility)
///
/// All configuration has been centralized in api_config.dart
///
/// USAGE: Import api_config.dart instead:
///   import '../config/api_config.dart';

import 'api_config.dart';

class MapboxConfig {
  static String get accessToken => ApiConfig.mapboxAccessToken;

  static String get mapboxStyleId => ApiConfig.mapboxStyleId;

  /// Get the Mapbox style URI for the native SDK
  static String getStyleUri() {
    return 'mapbox://styles/${ApiConfig.mapboxStyleId}';
  }

  /// Check if Mapbox is properly configured
  static bool isMapboxConfigured() {
    return ApiConfig.mapboxAccessToken.isNotEmpty;
  }
}
