import 'package:get_it/get_it.dart';
import '../../presentation/blocs/app/app_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/bus_tracking/bus_tracking_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(() => AppBloc());
  sl.registerFactory(() => AuthBloc());
  sl.registerFactory(() => BusTrackingBloc());

  // Use Cases
  // TODO: Register use cases when implemented
  
  // Repositories
  // TODO: Register repositories when implemented
  
  // Data Sources
  // TODO: Register data sources when implemented
  
  // External
  // TODO: Register external dependencies like HTTP client, location service, etc.
}