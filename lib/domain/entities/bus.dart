import 'package:equatable/equatable.dart';

class Bus extends Equatable {
  final String id;
  final String plateNumber;
  final String driverId;
  final String routeId;
  final BusStatus status;
  final BusLocation? currentLocation;
  final int capacity;
  final DateTime? lastUpdated;

  const Bus({
    required this.id,
    required this.plateNumber,
    required this.driverId,
    required this.routeId,
    required this.status,
    this.currentLocation,
    required this.capacity,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        id,
        plateNumber,
        driverId,
        routeId,
        status,
        currentLocation,
        capacity,
        lastUpdated,
      ];
}

enum BusStatus {
  active,
  inactive,
  maintenance,
  emergency
}

class BusLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  const BusLocation({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, speed, heading, timestamp];
}