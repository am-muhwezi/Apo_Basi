import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class BusTrackingEvent extends Equatable {
  const BusTrackingEvent();

  @override
  List<Object> get props => [];
}

class LoadBusTrackingData extends BusTrackingEvent {}

class StartBusTracking extends BusTrackingEvent {
  final String busId;

  const StartBusTracking({required this.busId});

  @override
  List<Object> get props => [busId];
}

class StopBusTracking extends BusTrackingEvent {
  final String busId;

  const StopBusTracking({required this.busId});

  @override
  List<Object> get props => [busId];
}

class UpdateBusLocation extends BusTrackingEvent {
  final String busId;
  final double latitude;
  final double longitude;

  const UpdateBusLocation({
    required this.busId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [busId, latitude, longitude];
}

class RefreshBusData extends BusTrackingEvent {}

// States
abstract class BusTrackingState extends Equatable {
  const BusTrackingState();

  @override
  List<Object> get props => [];
}

class BusTrackingInitial extends BusTrackingState {}

class BusTrackingLoading extends BusTrackingState {}

class BusTrackingLoaded extends BusTrackingState {
  final List<dynamic> buses;
  final List<dynamic> students;
  final List<dynamic> routes;

  const BusTrackingLoaded({
    required this.buses,
    required this.students,
    required this.routes,
  });

  @override
  List<Object> get props => [buses, students, routes];
}

class BusTrackingError extends BusTrackingState {
  final String message;

  const BusTrackingError(this.message);

  @override
  List<Object> get props => [message];
}

class BusLocationUpdated extends BusTrackingState {
  final String busId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const BusLocationUpdated({
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  List<Object> get props => [busId, latitude, longitude, timestamp];
}

// BLoC
class BusTrackingBloc extends Bloc<BusTrackingEvent, BusTrackingState> {
  BusTrackingBloc() : super(BusTrackingInitial()) {
    on<LoadBusTrackingData>(_onLoadBusTrackingData);
    on<StartBusTracking>(_onStartBusTracking);
    on<StopBusTracking>(_onStopBusTracking);
    on<UpdateBusLocation>(_onUpdateBusLocation);
    on<RefreshBusData>(_onRefreshBusData);
  }

  Future<void> _onLoadBusTrackingData(
    LoadBusTrackingData event,
    Emitter<BusTrackingState> emit,
  ) async {
    emit(BusTrackingLoading());
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Load actual data from repository
      // For demo purposes, create mock data
      final buses = _createMockBuses();
      final students = _createMockStudents();
      final routes = _createMockRoutes();
      
      emit(BusTrackingLoaded(
        buses: buses,
        students: students,
        routes: routes,
      ));
    } catch (e) {
      emit(BusTrackingError('Failed to load bus tracking data: ${e.toString()}'));
    }
  }

  Future<void> _onStartBusTracking(
    StartBusTracking event,
    Emitter<BusTrackingState> emit,
  ) async {
    try {
      // TODO: Start real-time tracking for specific bus
      // This would typically start a WebSocket connection or periodic polling
    } catch (e) {
      emit(BusTrackingError('Failed to start bus tracking: ${e.toString()}'));
    }
  }

  Future<void> _onStopBusTracking(
    StopBusTracking event,
    Emitter<BusTrackingState> emit,
  ) async {
    try {
      // TODO: Stop real-time tracking for specific bus
    } catch (e) {
      emit(BusTrackingError('Failed to stop bus tracking: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateBusLocation(
    UpdateBusLocation event,
    Emitter<BusTrackingState> emit,
  ) async {
    emit(BusLocationUpdated(
      busId: event.busId,
      latitude: event.latitude,
      longitude: event.longitude,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _onRefreshBusData(
    RefreshBusData event,
    Emitter<BusTrackingState> emit,
  ) async {
    add(LoadBusTrackingData());
  }

  List<dynamic> _createMockBuses() {
    return [
      {
        'id': 'bus_001',
        'plateNumber': 'UBF 123A',
        'driverId': 'driver_001',
        'routeId': 'route_001',
        'status': 'active',
        'capacity': 30,
        'currentStudents': 12,
      },
      {
        'id': 'bus_002',
        'plateNumber': 'UBF 456B',
        'driverId': 'driver_002',
        'routeId': 'route_002',
        'status': 'active',
        'capacity': 25,
        'currentStudents': 8,
      },
    ];
  }

  List<dynamic> _createMockStudents() {
    return [
      {
        'id': 'student_001',
        'firstName': 'Emma',
        'lastName': 'Johnson',
        'grade': '5',
        'routeId': 'route_001',
        'status': 'on_bus',
      },
      {
        'id': 'student_002',
        'firstName': 'Liam',
        'lastName': 'Smith',
        'grade': '3',
        'routeId': 'route_001',
        'status': 'waiting',
      },
    ];
  }

  List<dynamic> _createMockRoutes() {
    return [
      {
        'id': 'route_001',
        'name': 'Main Street Route',
        'description': 'Downtown to Greenfield Elementary',
        'stops': ['Central Park', 'Main Street', 'School Gate'],
      },
      {
        'id': 'route_002',
        'name': 'Suburban Route',
        'description': 'Residential areas to school',
        'stops': ['Oak Avenue', 'Pine Street', 'School Gate'],
      },
    ];
  }
}