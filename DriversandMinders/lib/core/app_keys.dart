/// Single source of truth for every SharedPreferences key used in the app.
///
/// Use these constants instead of inline string literals so that typos are
/// caught at compile-time and keys can be refactored from one place.
abstract final class AppKeys {
  AppKeys._();

  // ── Auth tokens (flat keys, needed before AppStore is warm) ───────────────
  static const accessToken  = 'access_token';
  static const refreshToken = 'refresh_token';

  // ── JSON store blobs (one read per key at startup) ────────────────────────
  static const userSession    = 'user_session';
  static const tripState      = 'trip_state';
  static const appPreferences = 'app_preferences';

  // ── API response cache ────────────────────────────────────────────────────
  static const cachedBusData   = 'cached_bus_data';
  static const cachedRouteData = 'cached_route_data';

  // ── Trip flat-keys (written by driver_start_shift_screen) ────────────────
  static const tripActive    = 'trip_active';
  static const tripId        = 'trip_id';
  static const tripType      = 'trip_type';
  static const tripStartTime = 'trip_start_time';
  static const busId         = 'bus_id';
  static const busNumber     = 'bus_number';
  static const userId        = 'user_id';
  static const userName      = 'user_name';
  static const driverName    = 'driver_name';

  // ── Theme (owned by ThemeService, not AppStore) ───────────────────────────
  static const themeMode = 'theme_mode';

  // ── Dynamic keys (built at runtime) ──────────────────────────────────────
  /// Offline attendance status for a specific student on a specific trip.
  static String attendance(int busId, String tripType, int studentId) =>
      'att_${busId}_${tripType}_$studentId';

  /// Pre-trip checklist item state by index.
  static String checklist(int index) => 'checklist_$index';
}
