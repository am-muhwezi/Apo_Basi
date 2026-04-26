import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_keys.dart';
import '../data/app_preferences.dart';
import '../data/trip_state.dart';
import '../data/user_session.dart';

/// Single source of truth for all in-memory app state backed by SharedPreferences.
///
/// Call [AppStore.initialize()] once in `main()` before `runApp()`.
/// After that every read is a plain synchronous getter — no `await`, no prefs.
///
/// Writes are debounced: mutations mark a key dirty and a 50 ms timer flushes
/// all dirty keys in a single `Future.wait` call, capping disk I/O regardless
/// of how many fields are mutated in quick succession.
class AppStore {
  AppStore._();

  static AppStore? _instance;

  static AppStore get instance {
    assert(_instance != null, 'AppStore.initialize() must be called in main()');
    return _instance!;
  }

  UserSession _user = UserSession.empty();
  TripState _trip = TripState.none();
  AppPreferences _prefs = AppPreferences.defaults();
  Map<String, dynamic>? _busData;
  Map<String, dynamic>? _routeData;

  UserSession get user => _user;
  TripState get trip => _trip;
  AppPreferences get prefs => _prefs;
  Map<String, dynamic>? get busData => _busData;
  Map<String, dynamic>? get routeData => _routeData;

  // ─── Deferred write queue ─────────────────────────────────────────────────

  Timer? _flushTimer;
  final Map<String, String> _dirty = {};

  void _scheduleDirty(String key, String encoded) {
    _dirty[key] = encoded;
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 50), _flush);
  }

  Future<void> _flush() async {
    if (_dirty.isEmpty) return;
    final snapshot = Map<String, String>.from(_dirty);
    _dirty.clear();
    final p = await SharedPreferences.getInstance();
    await Future.wait(snapshot.entries.map((e) => p.setString(e.key, e.value)));
  }

  /// Force an immediate flush of any pending writes. Call before signOut or
  /// before the app goes to background to guarantee nothing is lost.
  Future<void> flush() async {
    _flushTimer?.cancel();
    await _flush();
  }

  // ─── Initialisation ───────────────────────────────────────────────────────

  /// Load all stores from SharedPreferences. Call once in `main()`.
  static Future<void> initialize() async {
    final raw = await SharedPreferences.getInstance();
    final store = AppStore._();

    store._user = _parse(
      raw.getString(AppKeys.userSession),
      UserSession.fromJson,
      UserSession.empty(),
    );
    store._trip = _parse(
      raw.getString(AppKeys.tripState),
      TripState.fromJson,
      TripState.none(),
    );
    store._prefs = _parse(
      raw.getString(AppKeys.appPreferences),
      AppPreferences.fromJson,
      AppPreferences.defaults(),
    );

    final busRaw = raw.getString(AppKeys.cachedBusData);
    if (busRaw != null) {
      try {
        final decoded = jsonDecode(busRaw);
        store._busData = decoded is Map<String, dynamic> ? decoded : null;
      } catch (_) {}
    }
    final routeRaw = raw.getString(AppKeys.cachedRouteData);
    if (routeRaw != null) {
      try {
        final decoded = jsonDecode(routeRaw);
        store._routeData = decoded is Map<String, dynamic> ? decoded : null;
      } catch (_) {}
    }

    _instance = store;
  }

  // ─── Mutators ─────────────────────────────────────────────────────────────

  Future<void> saveUser(UserSession s) async {
    _user = s;
    _scheduleDirty(AppKeys.userSession, jsonEncode(s.toJson()));
  }

  Future<void> saveTrip(TripState s) async {
    _trip = s;
    _scheduleDirty(AppKeys.tripState, jsonEncode(s.toJson()));
  }

  Future<void> savePrefs(AppPreferences s) async {
    _prefs = s;
    _scheduleDirty(AppKeys.appPreferences, jsonEncode(s.toJson()));
  }

  Future<void> saveBusCache(Map<String, dynamic>? bus, Map<String, dynamic>? route) async {
    _busData = bus;
    _routeData = route;
    _scheduleDirty(AppKeys.cachedBusData, jsonEncode(bus));
    _scheduleDirty(AppKeys.cachedRouteData, jsonEncode(route));
  }

  // ─── Clear helpers ────────────────────────────────────────────────────────

  /// Resets all user-owned in-memory state to defaults. Synchronous, no I/O.
  /// Preferences (theme, settings) are preserved — they belong to the device,
  /// not to the logged-in user.
  void resetInMemory() {
    _user = UserSession.empty();
    _trip = TripState.none();
    _busData = null;
    _routeData = null;
    _dirty.clear();
    _flushTimer?.cancel();
  }

  /// Clears all user-owned keys from both memory and disk atomically.
  /// Call this on logout to prevent stale data leaking to the next session.
  static Future<void> clearAll() async {
    _instance?.resetInMemory();
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.remove(AppKeys.accessToken),
      p.remove(AppKeys.refreshToken),
      p.remove(AppKeys.userSession),
      p.remove(AppKeys.tripState),
      p.remove(AppKeys.cachedBusData),
      p.remove(AppKeys.cachedRouteData),
      // trip flat-keys written directly by driver_start_shift_screen
      p.remove(AppKeys.tripActive),
      p.remove(AppKeys.tripId),
      p.remove(AppKeys.tripType),
      p.remove(AppKeys.tripStartTime),
      p.remove(AppKeys.busId),
      p.remove(AppKeys.busNumber),
      p.remove(AppKeys.userId),
      p.remove(AppKeys.userName),
      p.remove(AppKeys.driverName),
    ]);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static T _parse<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
    T fallback,
  ) {
    if (raw == null) return fallback;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return fallback;
    }
  }
}
