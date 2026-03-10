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

    // Sync to backend and wait for response - throw error if it fails
    await _syncToBackend(latitude, longitude);
  }

  /// Sync home coordinates to Django backend (STAGING environment).
  /// Throws exception on failure so caller can handle the error.
  Future<void> _syncToBackend(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required. Please log in again.');
    }

    final url = Uri.parse(
      '${ApiConfig.apiBaseUrl}${ApiConfig.parentHomeLocationEndpoint}',
    );

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'homeLatitude': lat, 'homeLongitude': lng}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to save location to server: ${response.statusCode}');
    }
  }

  Future<bool> setHomeLocationFromAddress(String address) async {
    if (address.trim().isEmpty) return false;

    // Add country context to improve geocoding accuracy for Kenyan addresses
    String searchAddress = address;
    if (!address.toLowerCase().contains('kenya') &&
        !address.toLowerCase().contains('nairobi')) {
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
      throw Exception(
          'Could not find coordinates for this address. Please use "Detect my location" or try a different address.');
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
