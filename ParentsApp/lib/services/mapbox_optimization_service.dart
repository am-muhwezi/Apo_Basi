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
      'https://api.mapbox.com/optimized-trips/v1/mapbox/driving';

  // Cache keyed by busId — cleared when the screen disposes.
  static final Map<int, OptimizedRoute> _cache = {};

  /// Remove the cached route for [busId] (call from screen dispose).
  static void invalidate(int busId) => _cache.remove(busId);

  /// Clear all cached routes.
  static void clearAll() => _cache.clear();

  /// Compute (or return cached) optimised stop order for [busId].
  ///
  /// [schoolLocation] is the school coordinate.
  /// [busStops]       is the list of children's home stops.
  /// [tripType]       is `'pickup'` (homes→school) or `'dropoff'` (school→homes).
  ///
  /// Returns `null` only when [busStops] is empty.
  static Future<OptimizedRoute?> optimizeRoute({
    required int busId,
    required LatLng schoolLocation,
    required List<BusStop> busStops,
    required String tripType,
  }) async {
    if (busStops.isEmpty) return null;

    // Return cached result if available
    if (_cache.containsKey(busId)) return _cache[busId];

    // Single stop — no optimisation needed
    if (busStops.length == 1) {
      final result = OptimizedRoute(
        orderedStops: busStops,
        legDurations: const [0.0],
      );
      _cache[busId] = result;
      return result;
    }

    // Mapbox Optimization API supports at most 12 coordinates total.
    // school + homes must be ≤ 12, i.e. homes ≤ 11.
    if (busStops.length > 11) {
      final result = _nearestNeighbourSort(
        schoolLocation: schoolLocation,
        busStops: busStops,
        tripType: tripType,
      );
      _cache[busId] = result;
      return result;
    }

    try {
      final result = await _callOptimizationApi(
        schoolLocation: schoolLocation,
        busStops: busStops,
        tripType: tripType,
      );
      if (result != null) {
        _cache[busId] = result;
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
    _cache[busId] = fallback;
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Mapbox Optimized Trips API
  // ---------------------------------------------------------------------------

  static Future<OptimizedRoute?> _callOptimizationApi({
    required LatLng schoolLocation,
    required List<BusStop> busStops,
    required String tripType,
  }) async {
    // Build coordinate string and determine source/destination pins.
    //
    // dropoff (school → homes): school is fixed first, destination is any home
    //   coords: [school, home_1, ..., home_N]
    //   source=first, destination=any
    //
    // pickup (homes → school): school is fixed last, source is any home
    //   coords: [home_1, ..., home_N, school]
    //   source=any, destination=last

    late final String coordsString;
    late final String source;
    late final String destination;
    late final List<BusStop> inputOrder; // order of home stops in coord list

    if (tripType == 'dropoff') {
      inputOrder = busStops;
      final allCoords = [schoolLocation, ...busStops.map((s) => s.homeLatLng)];
      coordsString =
          allCoords.map((c) => '${c.longitude},${c.latitude}').join(';');
      source = 'first';
      destination = 'any';
    } else {
      // pickup
      inputOrder = busStops;
      final allCoords = [...busStops.map((s) => s.homeLatLng), schoolLocation];
      coordsString =
          allCoords.map((c) => '${c.longitude},${c.latitude}').join(';');
      source = 'any';
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

    // Extract only the home-stop waypoints (skip school coordinate).
    final orderedStops = <BusStop>[];
    for (final wp in waypoints) {
      final origIdx = wp['original_index'] as int;
      if (tripType == 'dropoff') {
        // original_index 0 is school; 1..N are homes
        if (origIdx == 0) continue;
        orderedStops.add(inputOrder[origIdx - 1]);
      } else {
        // pickup: original_index 0..N-1 are homes; N is school
        if (origIdx == busStops.length) continue;
        orderedStops.add(inputOrder[origIdx]);
      }
    }

    // Extract per-leg durations from the trip legs
    final legs = (trips[0]['legs'] as List?) ?? [];
    final legDurations = legs
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

    // Estimate leg durations: assume 30 km/h average in city traffic
    final legDurations = <double>[];
    LatLng prev = tripType == 'dropoff' ? schoolLocation : ordered.first.homeLatLng;
    final startIdx = tripType == 'dropoff' ? 0 : 1;
    for (int i = startIdx; i < ordered.length; i++) {
      final dist = _haversineKm(prev, ordered[i].homeLatLng);
      legDurations.add(dist / 30.0 * 3600); // seconds at 30 km/h
      prev = ordered[i].homeLatLng;
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
        cos(_deg2rad(a.latitude)) * cos(_deg2rad(b.latitude)) * sinDLon * sinDLon;
    return 2 * r * asin(sqrt(h));
  }

  static double _deg2rad(double deg) => deg * pi / 180.0;
}
