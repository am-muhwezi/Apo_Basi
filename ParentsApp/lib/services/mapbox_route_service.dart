import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

/// Service for fetching routes from Mapbox Directions API
class MapboxRouteService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

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
}
