import 'package:flutter/material.dart';
import '../presentation/driver_start_shift_screen/driver_start_shift_screen.dart';
import '../presentation/shared_login_screen/shared_login_screen.dart';
import '../presentation/driver_active_trip_screen/driver_active_trip_screen.dart';
import '../presentation/driver_trip_history_screen/driver_trip_history_screen.dart';
import '../presentation/busminder_start_shift_screen/busminder_start_shift_screen.dart';
import '../presentation/busminder_attendance_screen/busminder_attendance_screen/busminder_attendance_screen.dart';
import '../presentation/busminder_trip_progress_screen/busminder_trip_progress_screen.dart';
import '../presentation/busminder_trip_history_screen/busminder_trip_history_screen.dart';

class AppRoutes {
  // Routes
  static const String initial = '/';
  static const String sharedLogin = '/shared-login-screen';

  // Driver routes
  static const String driverStartShift = '/driver-start-shift-screen';
  static const String driverActiveTrip = '/driver-active-trip-screen';
  static const String driverTripHistory = '/driver-trip-history-screen';

  // Busminder routes
  static const String busminderStartShift = '/busminder-start-shift-screen';
  static const String busminderAttendance = '/busminder-attendance-screen';
  static const String busminderTripProgress = '/busminder-trip-progress-screen';
  static const String busminderTripHistory = '/busminder-trip-history-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SharedLoginScreen(),
    sharedLogin: (context) => const SharedLoginScreen(),
    driverStartShift: (context) => const DriverStartShiftScreen(),
    driverActiveTrip: (context) => const DriverActiveTripScreen(),
    driverTripHistory: (context) => const DriverTripHistoryScreen(),
    busminderStartShift: (context) => const BusminderStartShiftScreen(),
    busminderAttendance: (context) => const BusminderAttendanceScreen(),
    busminderTripProgress: (context) => const BusminderTripProgressScreen(),
    busminderTripHistory: (context) => const BusMinderTripHistoryScreen(),
  };
}
