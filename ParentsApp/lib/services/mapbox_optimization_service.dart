import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

/// A single bus stop (one child's home location).
class BusStop {
  final int childId;
  final LatLng homeLatLng;

  const BusStop({required this.childId, required this.homeLatLng});
}

/// The result of route optimization: an ordered list of stops and the
/// cumulative driving duration (seconds) from the first stop to each stop.
class OptimizedRoute {
  /// All home stops in the optimized travel order.
  final List<BusStop> orderedStops;

  /// Duration in seconds for each leg: `legDurations[i]` is the drive time
  /// from stop `i` to stop `i+1` (or from the school to stop 0 for dropoff).
  final List<double> legDurations;

  const OptimizedRoute({
    required this.orderedStops,
    required this.legDurations,
  });
}

/// Calls the Mapbox Optimization API to find the best stop ordering, then
/// caches the result per bus so subsequent WebSocket updates don't re-call.
///
/// Fallback: if the API fails or the bus has > 11 children (API limit is 12
/// coordinates total), a nearest-neighbour greedy sort is used instead.
class MapboxOptimizationService {
  static const String _optimizationBaseUrl =
      'https://api.mapbox.com/optimized-trips/v1/mapbox/driving-traffic';

  // Cache keyed by "busId|tripType" — so pickup and dropoff trips do not
  // share the same optimisation result.
  static final Map<String, OptimizedRoute> _cache = {};

  static String _cacheKey(int busId, String tripType) => '$busId|$tripType';

  /// Remove the cached route for [busId] (call from screen dispose).
  static void invalidate(int busId) {
    final prefix = '$busId|';
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clear all cached routes.
  static void clearAll() => _cache.clear();

  /// Compute (or return cached) optimised stop order for [busId].
  ///
  /// [schoolLocation] is the school coordinate.
  /// [busStops]       is the list of children's home stops.
  /// [tripType]       is `'pickup'` (homes→school) or `'dropoff'` (school→homes).
  /// [busLocation]    optional current bus position; used as the pickup start
  ///                  coordinate so Mapbox routes outward from the bus and
  ///                  comes back toward school (furthest-first).
  ///
  /// Returns `null` only when [busStops] is empty.
  static Future<OptimizedRoute?> optimizeRoute({
    required int busId,
    required LatLng schoolLocation,
    required List<BusStop> busStops,
    required String tripType,
    LatLng? busLocation,
  }) async {
    if (busStops.isEmpty) return null;

    final cacheKey = _cacheKey(busId, tripType);

    // Return cached result if available
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    // Single stop — no optimisation needed
    if (busStops.length == 1) {
      final result = OptimizedRoute(
        orderedStops: busStops,
        legDurations: const [0.0],
      );
      _cache[cacheKey] = result;
      return result;
    }

    // Mapbox Optimization API supports at most 12 coordinates total.
    // For pickup: start + homes + school = busStops.length + 2 ≤ 12 → homes ≤ 10.
    // For dropoff: school + homes = busStops.length + 1 ≤ 12 → homes ≤ 11.
    final maxStops = tripType == 'pickup' ? 10 : 11;
    if (busStops.length > maxStops) {
      final result = _nearestNeighbourSort(
        schoolLocation: schoolLocation,
        busStops: busStops,
        tripType: tripType,
      );
      _cache[cacheKey] = result;
      return result;
    }

    try {
      final result = await _callOptimizationApi(
        schoolLocation: schoolLocation,
        busStops: busStops,
        tripType: tripType,
        busLocation: busLocation,
      );
      if (result != null) {
        _cache[cacheKey] = result;
        return result;
      }
    } catch (_) {
      // Fall through to nearest-neighbour
    }

    // API failed — use greedy fallback
    final fallback = _nearestNeighbourSort(
      schoolLocation: schoolLocation,
      busStops: busStops,
      tripType: tripType,
    );
    _cache[cacheKey] = fallback;
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Mapbox Optimized Trips API
  // ---------------------------------------------------------------------------

  static Future<OptimizedRoute?> _callOptimizationApi({
    required LatLng schoolLocation,
    required List<BusStop> busStops,
    required String tripType,
    LatLng? busLocation,
  }) async {
    // Build coordinate string and determine source/destination pins.
    //
    // dropoff (school → homes):
    //   coords: [school, home_1, ..., home_N]
    //   source=first (school), destination=any
    //
    // pickup (homes → school):
    //   coords: [start, home_1, ..., home_N, school]
    //   source=first (bus/school start), destination=last (school)
    //   Routes outward from start → furthest homes first → back to school.

    late final String coordsString;
    late final String source;
    late final String destination;
    late final List<BusStop> inputOrder; // order of home stops in coord list
    // Number of extra leading coords before the first home stop (affects index offsets)
    late final int homeIndexOffset;

    if (tripType == 'dropoff') {
      inputOrder = busStops;
      homeIndexOffset = 1; // school at index 0
      final allCoords = [schoolLocation, ...busStops.map((s) => s.homeLatLng)];
      coordsString =
          allCoords.map((c) => '${c.longitude},${c.latitude}').join(';');
      source = 'first';
      destination = 'any';
    } else {
      // pickup — start from bus position (fallback: school acts as depot proxy)
      inputOrder = busStops;
      homeIndexOffset = 1; // start coord at index 0
      final startCoord = busLocation ?? schoolLocation;
      final allCoords = [
        startCoord,
        ...busStops.map((s) => s.homeLatLng),
        schoolLocation,
      ];
      coordsString =
          allCoords.map((c) => '${c.longitude},${c.latitude}').join(';');
      source = 'first';
      destination = 'last';
    }

    final url = Uri.parse(
      '$_optimizationBaseUrl/$coordsString'
      '?roundtrip=false&source=$source&destination=$destination'
      '&geometries=geojson&overview=full'
      '&access_token=${ApiConfig.mapboxAccessToken}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final waypointsRaw = data['waypoints'] as List?;
    final trips = data['trips'] as List?;
    if (waypointsRaw == null || trips == null || trips.isEmpty) return null;

    // Each waypoint has a `waypoint_index` (its position in the optimized trip)
    // and an `original_index` (its position in the input coordinates).
    // Sort waypoints by waypoint_index to get the travel order.
    final waypoints = List<Map<String, dynamic>>.from(waypointsRaw);
    waypoints.sort((a, b) =>
        (a['waypoint_index'] as int).compareTo(b['waypoint_index'] as int));

    // Extract only the home-stop waypoints (skip start/school coordinates).
    //
    // dropoff: origIdx 0 = school (skip); 1..N = homes → inputOrder[origIdx-1]
    // pickup:  origIdx 0 = start (skip); 1..N = homes → inputOrder[origIdx-1];
    //          origIdx N+1 = school (skip)
    final orderedStops = <BusStop>[];
    for (final wp in waypoints) {
      final origIdx = wp['original_index'] as int;
      if (tripType == 'dropoff') {
        if (origIdx == 0) continue; // school start
        orderedStops.add(inputOrder[origIdx - homeIndexOffset]);
      } else {
        // pickup
        if (origIdx == 0) continue; // bus/school start
        if (origIdx == busStops.length + 1) continue; // school end
        orderedStops.add(inputOrder[origIdx - homeIndexOffset]);
      }
    }

    // Extract per-leg durations from the trip legs.
    //
    // For pickup we prepend a "start→first_home" leg that has no business
    // meaning (the driver is already heading out), so we skip it.
    // legDurations[i] = travel time from orderedStops[i] to orderedStops[i+1]
    //                   (last entry = travel from last home to school).
    final allLegs = (trips[0]['legs'] as List?) ?? [];
    final legSkip = (tripType == 'pickup') ? 1 : 0; // skip start→first_home leg
    final legDurations = allLegs
        .skip(legSkip)
        .map<double>((leg) => ((leg['duration'] as num?)?.toDouble()) ?? 0.0)
        .toList();

    // Pad if the API returned fewer legs than stops
    while (legDurations.length < orderedStops.length) {
      legDurations.add(0.0);
    }

    return OptimizedRoute(
      orderedStops: orderedStops,
      legDurations: legDurations,
    );
  }

  // ---------------------------------------------------------------------------
  // Nearest-neighbour greedy fallback (no extra API call)
  // ---------------------------------------------------------------------------

  static OptimizedRoute _nearestNeighbourSort({
    required LatLng schoolLocation,
    required List<BusStop> busStops,
    required String tripType,
  }) {
    final remaining = List<BusStop>.from(busStops);
    final ordered = <BusStop>[];

    // Starting point for distance calculations
    LatLng current = tripType == 'dropoff'
        ? schoolLocation
        : remaining.isNotEmpty
            ? remaining.first.homeLatLng
            : schoolLocation;

    if (tripType == 'pickup') {
      // For pickup, start from the geographically first home (farthest from school)
      // Simple approach: just greedily pick nearest unvisited from current
      current = schoolLocation; // measure from school to find farthest first
      // Find stop farthest from school as starting point
      BusStop? farthest;
      double maxDist = -1;
      for (final stop in remaining) {
        final d = _haversineKm(schoolLocation, stop.homeLatLng);
        if (d > maxDist) {
          maxDist = d;
          farthest = stop;
        }
      }
      if (farthest != null) {
        current = farthest.homeLatLng;
        ordered.add(farthest);
        remaining.remove(farthest);
      }
    }

    while (remaining.isNotEmpty) {
      BusStop? nearest;
      double minDist = double.infinity;
      for (final stop in remaining) {
        final d = _haversineKm(current, stop.homeLatLng);
        if (d < minDist) {
          minDist = d;
          nearest = stop;
        }
      }
      if (nearest != null) {
        ordered.add(nearest);
        current = nearest.homeLatLng;
        remaining.remove(nearest);
      }
    }

    // Estimate leg durations at 30 km/h average (city traffic).
    //
    // legDurations[i] = time from ordered[i] to ordered[i+1].
    // Last entry = time from ordered[N-1] to school (same convention as API).
    final legDurations = <double>[];

    if (tripType == 'dropoff') {
      // First leg: school → ordered[0]
      LatLng prev = schoolLocation;
      for (final stop in ordered) {
        legDurations.add(_haversineKm(prev, stop.homeLatLng) / 30.0 * 3600);
        prev = stop.homeLatLng;
      }
    } else {
      // Legs between homes: ordered[i] → ordered[i+1]
      for (int i = 0; i < ordered.length - 1; i++) {
        legDurations.add(
            _haversineKm(ordered[i].homeLatLng, ordered[i + 1].homeLatLng) /
                30.0 *
                3600);
      }
      // Final leg: last home → school
      legDurations.add(
          _haversineKm(ordered.last.homeLatLng, schoolLocation) / 30.0 * 3600);
    }

    while (legDurations.length < ordered.length) {
      legDurations.add(0.0);
    }

    return OptimizedRoute(orderedStops: ordered, legDurations: legDurations);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Haversine distance in km between two lat/lng points.
  static double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final h = sinDLat * sinDLat +
        cos(_deg2rad(a.latitude)) *
            cos(_deg2rad(b.latitude)) *
            sinDLon *
            sinDLon;
    return 2 * r * asin(sqrt(h));
  }

  static double _deg2rad(double deg) => deg * pi / 180.0;
}
