/// Mapbox Configuration (Backward Compatibility)
///
/// This file provides backward compatibility for code that imports mapbox_config.
/// All configuration has been centralized in api_config.dart
///
/// USAGE: Import api_config.dart instead:
///   import '../config/api_config.dart';
///   ApiConfig.getMapboxTileUrl()

import 'api_config.dart';

class MapboxConfig {
  /// Use ApiConfig.mapboxAccessToken instead
  static String get accessToken => ApiConfig.mapboxAccessToken;

  /// Use ApiConfig.mapboxStyleId instead
  static String get mapboxStyleId => ApiConfig.mapboxStyleId;

  /// Use ApiConfig.getMapboxTileUrl() instead
  static String getTileUrl() {
    return ApiConfig.getMapboxTileUrl();
  }

  /// Check if Mapbox is properly configured
  static bool isMapboxConfigured() {
    return ApiConfig.mapboxAccessToken.isNotEmpty;
  }

  /// Get Mapbox attribution text
  static String getAttribution() {
    return '© Mapbox';
  }
}
