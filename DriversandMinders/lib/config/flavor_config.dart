enum Flavor { dev, staging, prod }

class FlavorConfig {
  static Flavor _flavor = Flavor.prod;
  static String _apiBaseUrl = '';

  static void initialize({required Flavor flavor, required String apiBaseUrl}) {
    _flavor = flavor;
    _apiBaseUrl = apiBaseUrl;
  }

  static Flavor get flavor => _flavor;

  /// Empty string means no flavor was set — ApiConfig falls back to dotenv (local dev).
  static String get apiBaseUrl => _apiBaseUrl;

  static bool get isDev => _flavor == Flavor.dev;
  static bool get isStaging => _flavor == Flavor.staging;
  static bool get isProd => _flavor == Flavor.prod;
}
