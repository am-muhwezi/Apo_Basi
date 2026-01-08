import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

/// Service for fetching routes from Mapbox Directions API and Map Matching
class MapboxRouteService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  static const String _matchingUrl = 'https://api.mapbox.com/matching/v5/mapbox';

  /// Fetch route between two coordinates
  ///
  /// Returns a list of LatLng points representing the route polyline
  static Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving', // driving, walking, cycling, driving-traffic
  }) async {
    try {
      final coordinates = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      final url = Uri.parse(
        '$_baseUrl/$profile/$coordinates?geometries=geojson&overview=full&access_token=${ApiConfig.mapboxAccessToken}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convert coordinates to LatLng points
          return coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching route from Mapbox: $e');
      return [];
    }
  }

  /// Get estimated duration and distance for a route
  static Future<Map<String, dynamic>?> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving',
  }) async {
    try {
      final coordinates = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      final url = Uri.parse(
        '$_baseUrl/$profile/$coordinates?geometries=geojson&overview=full&access_token=${ApiConfig.mapboxAccessToken}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          return {
            'duration': route['duration'], // in seconds
            'distance': route['distance'], // in meters
            'duration_typical': route['duration_typical'], // typical duration in traffic
          };
        }
      }

      return null;
    } catch (e) {
      print('Error fetching route info from Mapbox: $e');
      return null;
    }
  }

  /// Snap GPS coordinates to roads using Mapbox Map Matching API
  ///
  /// This is crucial for displaying accurate bus location on roads
  /// [coordinates] - List of GPS coordinates from the bus
  /// [radiuses] - Search radius for each point (in meters), use null for auto
  /// Returns snapped coordinates that follow actual roads
  static Future<Map<String, dynamic>?> snapToRoads({
    required List<LatLng> coordinates,
    List<int?>? radiuses,
    String profile = 'driving',
  }) async {
    try {
      // Build coordinates string: "lon1,lat1;lon2,lat2;..."
      final coordsString = coordinates
          .map((coord) => '${coord.longitude},${coord.latitude}')
          .join(';');

      // Build radiuses parameter if provided
      String radiusesParam = '';
      if (radiuses != null && radiuses.isNotEmpty) {
        radiusesParam = '&radiuses=${radiuses.map((r) => r?.toString() ?? '').join(';')}';
      }

      final url = Uri.parse(
        '$_matchingUrl/$profile/$coordsString?geometries=geojson&overview=full&steps=true&timestamps=&access_token=${ApiConfig.mapboxAccessToken}$radiusesParam',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['matchings'] != null && (data['matchings'] as List).isNotEmpty) {
          final matching = data['matchings'][0];
          final geometry = matching['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convert coordinates to LatLng points
          final snappedPoints = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          return {
            'snappedCoordinates': snappedPoints,
            'confidence': matching['confidence'], // Matching confidence score
            'duration': matching['duration'], // Duration in seconds
            'distance': matching['distance'], // Distance in meters
          };
        }
      }

      return null;
    } catch (e) {
      print('Error snapping to roads: $e');
      return null;
    }
  }

  /// Snap a single GPS point to the nearest road
  ///
  /// Useful for real-time bus location updates
  static Future<LatLng?> snapSinglePointToRoad({
    required LatLng coordinate,
    int radius = 25, // Search radius in meters
    String profile = 'driving',
  }) async {
    try {
      final result = await snapToRoads(
        coordinates: [coordinate],
        radiuses: [radius],
        profile: profile,
      );

      if (result != null && result['snappedCoordinates'] != null) {
        final snapped = result['snappedCoordinates'] as List<LatLng>;
        if (snapped.isNotEmpty) {
          return snapped.first;
        }
      }

      // If snapping fails, return original coordinate
      return coordinate;
    } catch (e) {
      print('Error snapping single point: $e');
      return coordinate;
    }
  }

  /// Calculate ETA (Estimated Time of Arrival) in minutes
  ///
  /// Returns the estimated time for the bus to reach the destination
  static Future<int?> calculateETA({
    required LatLng currentLocation,
    required LatLng destination,
    String profile = 'driving-traffic', // Use traffic data for accuracy
  }) async {
    try {
      final routeInfo = await getRouteInfo(
        origin: currentLocation,
        destination: destination,
        profile: profile,
      );

      if (routeInfo != null && routeInfo['duration'] != null) {
        // Convert seconds to minutes and round up
        final durationSeconds = routeInfo['duration'] as num;
        return (durationSeconds / 60).ceil();
      }

      return null;
    } catch (e) {
      print('Error calculating ETA: $e');
      return null;
    }
  }

  /// Calculate distance in kilometers
  static Future<double?> calculateDistance({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving',
  }) async {
    try {
      final routeInfo = await getRouteInfo(
        origin: origin,
        destination: destination,
        profile: profile,
      );

      if (routeInfo != null && routeInfo['distance'] != null) {
        // Convert meters to kilometers
        final distanceMeters = routeInfo['distance'] as num;
        return distanceMeters / 1000;
      }

      return null;
    } catch (e) {
      print('Error calculating distance: $e');
      return null;
    }
  }

  /// Get comprehensive trip information including ETA, distance, and route
  static Future<Map<String, dynamic>?> getTripInformation({
    required LatLng busLocation,
    required LatLng homeLocation,
    String profile = 'driving-traffic',
  }) async {
    try {
      final coordinates = '${busLocation.longitude},${busLocation.latitude};${homeLocation.longitude},${homeLocation.latitude}';
      final url = Uri.parse(
        '$_baseUrl/$profile/$coordinates?geometries=geojson&overview=full&steps=true&access_token=${ApiConfig.mapboxAccessToken}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convert coordinates to LatLng points
          final routePoints = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          final durationSeconds = route['duration'] as num;
          final distanceMeters = route['distance'] as num;

          return {
            'route': routePoints,
            'eta': (durationSeconds / 60).ceil(), // Minutes
            'duration': durationSeconds.toInt(), // Seconds
            'distance': (distanceMeters / 1000).toStringAsFixed(2), // Kilometers
            'distanceMeters': distanceMeters.toInt(),
          };
        }
      }

      return null;
    } catch (e) {
      print('Error getting trip information: $e');
      return null;
    }
  }
}
