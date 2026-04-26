/// Typed representation of an active trip stored in memory.
///
/// Consolidates the previously scattered keys:
///   trip_id / current_trip_id     → [tripId]
///   trip_type / current_trip_type → [tripType]
///   trip_active / trip_in_progress → [isActive]
///   bus_id / current_bus_id       → [busId]
///
/// Populated when a trip starts; reset to [TripState.none] when it ends.
class TripState {
  final bool isActive;
  final int? tripId;
  final int? busId;
  final String busNumber;
  /// Either `'pickup'`, `'dropoff'`, or `''` when no active trip.
  final String tripType;
  final DateTime? startTime;

  const TripState({
    required this.isActive,
    this.tripId,
    this.busId,
    this.busNumber = '',
    this.tripType = '',
    this.startTime,
  });

  factory TripState.none() => const TripState(isActive: false);

  factory TripState.fromJson(Map<String, dynamic> j) => TripState(
        isActive: (j['is_active'] as bool?) ?? false,
        tripId: (j['trip_id'] as num?)?.toInt(),
        busId: (j['bus_id'] as num?)?.toInt(),
        busNumber: (j['bus_number'] as String?) ?? '',
        tripType: (j['trip_type'] as String?) ?? '',
        startTime: j['start_time'] != null
            ? DateTime.tryParse(j['start_time'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'is_active': isActive,
        'trip_id': tripId,
        'bus_id': busId,
        'bus_number': busNumber,
        'trip_type': tripType,
        'start_time': startTime?.toIso8601String(),
      };

  TripState copyWith({
    bool? isActive,
    int? tripId,
    int? busId,
    String? busNumber,
    String? tripType,
    DateTime? startTime,
  }) =>
      TripState(
        isActive: isActive ?? this.isActive,
        tripId: tripId ?? this.tripId,
        busId: busId ?? this.busId,
        busNumber: busNumber ?? this.busNumber,
        tripType: tripType ?? this.tripType,
        startTime: startTime ?? this.startTime,
      );
}
