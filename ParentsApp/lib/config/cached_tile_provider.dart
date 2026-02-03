import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Custom tile provider that caches map tiles
/// Uses Flutter's built-in NetworkImage caching for better performance
class CachedTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(TileCoordinates coordinates, TileLayer options) {
    // Build tile URL
    final url = getTileUrl(coordinates, options);

    // Use NetworkImage which has built-in caching
    return NetworkImage(url);
  }
}
