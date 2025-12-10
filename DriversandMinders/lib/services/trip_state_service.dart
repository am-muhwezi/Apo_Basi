import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage trip state persistence
/// Handles saving and retrieving active trip information
class TripStateService {
  static const String _keyTripActive = 'trip_active';
  static const String _keyTripId = 'trip_id';
  static const String _keyTripType = 'trip_type';
  static const String _keyTripStartTime = 'trip_start_time';
  static const String _keyBusId = 'bus_id';
  static const String _keyBusNumber = 'bus_number';

  /// Save trip state when trip starts
  Future<void> saveTripState({
    required int tripId,
    required String tripType,
    required DateTime startTime,
    required int busId,
    required String busNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyTripActive, true);
    await prefs.setInt(_keyTripId, tripId);
    await prefs.setString(_keyTripType, tripType);
    await prefs.setString(_keyTripStartTime, startTime.toIso8601String());
    await prefs.setInt(_keyBusId, busId);
    await prefs.setString(_keyBusNumber, busNumber);
  }

  /// Clear trip state when trip ends
  Future<void> clearTripState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyTripActive);
    await prefs.remove(_keyTripId);
    await prefs.remove(_keyTripType);
    await prefs.remove(_keyTripStartTime);
    await prefs.remove(_keyBusId);
    await prefs.remove(_keyBusNumber);
  }

  /// Check if there's an active trip
  Future<bool> hasActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTripActive) ?? false;
  }

  /// Get active trip information
  Future<Map<String, dynamic>?> getActiveTripInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final isActive = prefs.getBool(_keyTripActive) ?? false;
    if (!isActive) return null;

    return {
      'tripId': prefs.getInt(_keyTripId),
      'tripType': prefs.getString(_keyTripType),
      'startTime': prefs.getString(_keyTripStartTime) != null
          ? DateTime.parse(prefs.getString(_keyTripStartTime)!)
          : null,
      'busId': prefs.getInt(_keyBusId),
      'busNumber': prefs.getString(_keyBusNumber),
    };
  }

  /// Get trip duration in minutes
  Future<int> getTripDuration() async {
    final tripInfo = await getActiveTripInfo();
    if (tripInfo == null || tripInfo['startTime'] == null) return 0;

    final startTime = tripInfo['startTime'] as DateTime;
    final duration = DateTime.now().difference(startTime);
    return duration.inMinutes;
  }
}
