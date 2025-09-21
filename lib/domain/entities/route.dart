import 'package:equatable/equatable.dart';

class BusRoute extends Equatable {
  final String id;
  final String name;
  final String schoolId;
  final List<BusStop> stops;
  final List<RouteCoordinate> coordinates;
  final String description;
  final Duration estimatedDuration;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusRoute({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.stops,
    required this.coordinates,
    required this.description,
    required this.estimatedDuration,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
        id,
        name,
        schoolId,
        stops,
        coordinates,
        description,
        estimatedDuration,
        startTime,
        endTime,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class BusStop extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final int sequence;
  final Duration estimatedArrivalTime;
  final bool isPickupPoint;
  final bool isDropoffPoint;

  const BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.sequence,
    required this.estimatedArrivalTime,
    required this.isPickupPoint,
    required this.isDropoffPoint,
  });

  @override
  List<Object> get props => [
        id,
        name,
        latitude,
        longitude,
        address,
        sequence,
        estimatedArrivalTime,
        isPickupPoint,
        isDropoffPoint,
      ];
}

class RouteCoordinate extends Equatable {
  final double latitude;
  final double longitude;
  final int sequence;

  const RouteCoordinate({
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });

  @override
  List<Object> get props => [latitude, longitude, sequence];
}