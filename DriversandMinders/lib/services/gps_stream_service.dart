import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Single source of truth for GPS positions in the Flutter UI layer.
///
/// Priority:
///   1. Native EventChannel (`com.apobasi.driver/gps_stream`) — emitted by
///      LocationTrackingService.kt during active trips via FusedLocationProvider.
///      Battery-optimal, survives background, no duplicate GPS radio usage.
///   2. Geolocator fallback — used on the home screen before a trip starts,
///      when the native foreground service is not yet running.
///
/// All screens subscribe to [stream] and cancel only their own listener on
/// dispose — the underlying GPS source stays warm across navigation events.
class GpsStreamService {
  static final GpsStreamService _instance = GpsStreamService._internal();
  factory GpsStreamService() => _instance;
  GpsStreamService._internal();

  static const EventChannel _nativeChannel =
      EventChannel('com.apobasi.driver/gps_stream');

  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();

  StreamSubscription<Object?>? _nativeSub;
  StreamSubscription<Position>? _geoSub;

  /// Non-null when native service sent a position in the last [_nativeTimeout].
  Timer? _nativeSilenceTimer;
  bool _nativeActive = false;

  /// If no native event arrives within this window, activate Geolocator.
  static const _nativeTimeout = Duration(seconds: 8);

  // ── Public state ─────────────────────────────────────────────────────────

  Position? lastKnownPosition;
  bool isConnected = false;
  String accuracyText = 'Searching...';

  bool get isRunning => _nativeSub != null || _geoSub != null;

  /// Broadcast stream of GPS positions. Subscribe freely — the underlying
  /// source is not affected by individual listener cancellations.
  Stream<Position> get stream => _controller.stream;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Start GPS. Idempotent — safe to call from multiple screens.
  void ensureStarted() {
    _listenNative();
    // Start Geolocator immediately as fallback; native will suppress it once
    // the foreground service begins emitting positions.
    if (!_nativeActive) _startGeolocator();
  }

  /// Stop all GPS (call on explicit user disable or logout).
  void stop() {
    _nativeSilenceTimer?.cancel();
    _nativeSub?.cancel();
    _nativeSub = null;
    _geoSub?.cancel();
    _geoSub = null;
    _nativeActive = false;
    isConnected = false;
    accuracyText = 'Disabled';
    lastKnownPosition = null;
  }

  // ── Native EventChannel ──────────────────────────────────────────────────

  void _listenNative() {
    if (_nativeSub != null) return;
    _nativeSub = _nativeChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        final map = Map<String, dynamic>.from(event as Map);
        final connected = map['connected'] as bool? ?? true;

        if (!connected) {
          // Native service stopped — fall back to Geolocator
          _nativeActive = false;
          _nativeSilenceTimer?.cancel();
          _startGeolocator();
          return;
        }

        // Native position received — suppress Geolocator
        _nativeActive = true;
        _stopGeolocator();

        // Reset silence timer: if native goes quiet, reactivate Geolocator
        _nativeSilenceTimer?.cancel();
        _nativeSilenceTimer = Timer(_nativeTimeout, () {
          _nativeActive = false;
          _startGeolocator();
        });

        final pos = _buildPosition(map);
        if (pos == null) return;

        lastKnownPosition = pos;
        isConnected = true;
        final acc = (map['accuracy'] as num?)?.toDouble() ?? 0.0;
        accuracyText = acc > 0 ? '±${acc.toInt()}m' : 'GPS Active';

        if (!_controller.isClosed) _controller.add(pos);
      },
      onError: (_) {
        // EventChannel error → fall back to Geolocator
        _nativeActive = false;
        _startGeolocator();
      },
    );
  }

  // ── Geolocator fallback ──────────────────────────────────────────────────

  void _startGeolocator() {
    if (_geoSub != null) return; // already running
    _geoSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (Position pos) {
        if (_nativeActive) {
          // Native took over — stop Geolocator
          _stopGeolocator();
          return;
        }
        lastKnownPosition = pos;
        isConnected = true;
        accuracyText = '±${pos.accuracy.toInt()}m';
        if (!_controller.isClosed) _controller.add(pos);
      },
      onError: (_) {
        isConnected = false;
        accuracyText = 'Error';
      },
    );
  }

  void _stopGeolocator() {
    _geoSub?.cancel();
    _geoSub = null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Build a [Position] from the native EventChannel map.
  Position? _buildPosition(Map<String, dynamic> map) {
    final lat = (map['lat'] as num?)?.toDouble();
    final lng = (map['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final accuracy = (map['accuracy'] as num?)?.toDouble() ?? 0.0;
    // Native sends speed in km/h; Position expects m/s
    final speedMs = ((map['speed'] as num?)?.toDouble() ?? 0.0) / 3.6;

    return Position(
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: speedMs,
      speedAccuracy: 0.0,
      timestamp: DateTime.now(),
    );
  }
}
