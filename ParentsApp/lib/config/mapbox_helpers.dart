import 'package:latlong2/latlong.dart' as ll;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Convert latlong2 LatLng to Mapbox Point
Point latLngToPoint(ll.LatLng coord) {
  return Point(coordinates: Position(coord.longitude, coord.latitude));
}

/// Convert list of latlong2 LatLng to list of Mapbox Position
List<Position> latLngListToPositions(List<ll.LatLng> coords) {
  return coords.map((c) => Position(c.longitude, c.latitude)).toList();
}
