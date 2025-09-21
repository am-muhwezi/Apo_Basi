import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object> get props => [];
}

class CheckAuthStatus extends AppEvent {}

class AppStarted extends AppEvent {}

class UserLoggedIn extends AppEvent {
  final String userId;
  final String role;

  const UserLoggedIn({required this.userId, required this.role});

  @override
  List<Object> get props => [userId, role];
}

class UserLoggedOut extends AppEvent {}

// States
abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object> get props => [];
}

class AppInitial extends AppState {}

class AppLoading extends AppState {}

class AppAuthenticated extends AppState {
  final String userId;
  final String role;

  const AppAuthenticated({required this.userId, required this.role});

  @override
  List<Object> get props => [userId, role];
}

class AppUnauthenticated extends AppState {}

class AppError extends AppState {
  final String message;

  const AppError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AppStarted>(_onAppStarted);
    on<UserLoggedIn>(_onUserLoggedIn);
    on<UserLoggedOut>(_onUserLoggedOut);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AppState> emit,
  ) async {
    emit(AppLoading());
    
    try {
      // Simulate auth check delay
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Check actual authentication status
      // For now, simulate unauthenticated state
      emit(AppUnauthenticated());
    } catch (e) {
      emit(AppError(e.toString()));
    }
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AppState> emit,
  ) async {
    add(CheckAuthStatus());
  }

  Future<void> _onUserLoggedIn(
    UserLoggedIn event,
    Emitter<AppState> emit,
  ) async {
    emit(AppAuthenticated(userId: event.userId, role: event.role));
  }

  Future<void> _onUserLoggedOut(
    UserLoggedOut event,
    Emitter<AppState> emit,
  ) async {
    // TODO: Clear user data and tokens
    emit(AppUnauthenticated());
  }
}