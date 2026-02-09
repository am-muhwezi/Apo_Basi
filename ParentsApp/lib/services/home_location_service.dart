import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

/// Persists the parent's static home location.
/// Ensures home coordinates remain constant even when the device moves.
class HomeLocationService {
  static const String _homeLatKey = 'home_latitude';
  static const String _homeLngKey = 'home_longitude';
  static const String _homeAddressKey = 'home_address';

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
