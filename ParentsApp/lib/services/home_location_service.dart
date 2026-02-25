import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import '../config/api_config.dart';

/// Persists the parent's static home location.
/// Ensures home coordinates remain constant even when the device moves.
class HomeLocationService {
  static const String _homeLatKey = 'home_latitude';
  static const String _homeLngKey = 'home_longitude';
  static const String _homeAddressKey = 'home_address';
  static const String _authTokenKey = 'access_token';

  Future<void> clearHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_homeLatKey);
    await prefs.remove(_homeLngKey);
    await prefs.remove(_homeAddressKey);
  }

  Future<void> setHomeLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_homeLatKey, latitude);
    await prefs.setDouble(_homeLngKey, longitude);
    if (address != null && address.isNotEmpty) {
      await prefs.setString(_homeAddressKey, address);
    }
    _syncToBackend(latitude, longitude);
  }

  /// Fire-and-forget sync of home coordinates to the Django backend.
  /// Failures are silently swallowed — local storage is the source of truth.
  Future<void> _syncToBackend(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      if (token == null || token.isEmpty) return;

      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}${ApiConfig.parentHomeLocationEndpoint}',
      );
      await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'homeLatitude': lat, 'homeLongitude': lng}),
      );
    } catch (_) {
      // Backend sync is best-effort; local prefs remain the source of truth
    }
  }

  Future<bool> setHomeLocationFromAddress(String address) async {
    try {
      if (address.trim().isEmpty) return false;

      // Add country context to improve geocoding accuracy for Kenyan addresses
      String searchAddress = address;
      if (!address.toLowerCase().contains('kenya') && !address.toLowerCase().contains('nairobi')) {
        searchAddress = '$address, Nairobi, Kenya';
      }

      final results = await locationFromAddress(searchAddress);
      if (results.isNotEmpty) {
        final loc = results.first;
        await setHomeLocation(
          latitude: loc.latitude,
          longitude: loc.longitude,
          address: address,
        );
        return true;
      } else {
        // Persist address only if geocoding failed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_homeAddressKey, address);
        return false;
      }
    } catch (e) {
      // Persist address only if geocoding failed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_homeAddressKey, address);
      return false;
    }
  }

  Future<LatLng?> getHomeCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_homeLatKey);
    final lng = prefs.getDouble(_homeLngKey);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<String?> getHomeAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_homeAddressKey);
  }
}
