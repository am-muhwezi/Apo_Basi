/// Bus Location Model
///
/// Represents real-time location data for a bus.
/// Used for displaying bus position on map and tracking updates.

class BusLocation {
  final int busId;
  final String busNumber;
  final double latitude;
  final double longitude;
  final double? speed; // km/h
  final double? heading; // degrees (0-360)
  final bool isActive;
  final DateTime timestamp;

  BusLocation({
    required this.busId,
    required this.busNumber,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.isActive,
    required this.timestamp,
  });

  /// Create from JSON (Socket.IO or HTTP response)
  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      busId: json['busId'] ?? json['bus_id'],
      busNumber: json['busNumber'] ?? json['bus_number'] ?? '',
      latitude: _parseDouble(json['lat'] ?? json['latitude']),
      longitude: _parseDouble(json['lng'] ?? json['longitude']),
      speed: json['speed'] != null ? _parseDouble(json['speed']) : null,
      heading: json['heading'] != null ? _parseDouble(json['heading']) : null,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Helper to parse double from dynamic (handles String or int)
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'busNumber': busNumber,
      'lat': latitude,
      'lng': longitude,
      'speed': speed,
      'heading': heading,
      'isActive': isActive,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if location data is stale (no update in X seconds)
  bool isStale(Duration threshold) {
    return DateTime.now().difference(timestamp) > threshold;
  }

  /// Get human-readable time since last update
  String getTimeSinceUpdate() {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inSeconds < 5) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  /// Copy with updated fields
  BusLocation copyWith({
    int? busId,
    String? busNumber,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    bool? isActive,
    DateTime? timestamp,
  }) {
    return BusLocation(
      busId: busId ?? this.busId,
      busNumber: busNumber ?? this.busNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      isActive: isActive ?? this.isActive,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'BusLocation(busId: $busId, lat: $latitude, lng: $longitude, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BusLocation &&
        other.busId == busId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return busId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        timestamp.hashCode;
  }
}

/// Location Connection State
///
/// Represents the state of Socket.IO connection for real-time updates
enum LocationConnectionState {
  disconnected, // Not connected to Socket.IO server
  connecting, // Attempting to connect
  connected, // Successfully connected and receiving updates
  error, // Connection error occurred
}

/// Bus Location State
///
/// Complete state for bus location tracking including connection status
class BusLocationState {
  final BusLocation? location;
  final LocationConnectionState connectionState;
  final String? errorMessage;
  final bool isSubscribed;
  final int? subscribedBusId;

  const BusLocationState({
    this.location,
    this.connectionState = LocationConnectionState.disconnected,
    this.errorMessage,
    this.isSubscribed = false,
    this.subscribedBusId,
  });

  /// Check if location is stale
  bool get isLocationStale {
    if (location == null) return true;
    return location!.isStale(const Duration(seconds: 30));
  }

  /// Check if location is offline
  bool get isLocationOffline {
    if (location == null) return true;
    return location!.isStale(const Duration(minutes: 5));
  }

  /// Check if connected and receiving updates
  bool get isConnectedAndActive {
    return connectionState == LocationConnectionState.connected &&
        isSubscribed &&
        location != null &&
        !isLocationOffline;
  }

  /// Copy with updated fields
  BusLocationState copyWith({
    BusLocation? location,
    LocationConnectionState? connectionState,
    String? errorMessage,
    bool? isSubscribed,
    int? subscribedBusId,
    bool clearError = false,
  }) {
    return BusLocationState(
      location: location ?? this.location,
      connectionState: connectionState ?? this.connectionState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscribedBusId: subscribedBusId ?? this.subscribedBusId,
    );
  }

  @override
  String toString() {
    return 'BusLocationState(connection: $connectionState, subscribed: $isSubscribed, hasLocation: ${location != null})';
  }
}
