import 'package:flutter/material.dart';
import '../presentation/driver_start_shift_screen/driver_start_shift_screen.dart';
import '../presentation/shared_login_screen/shared_login_screen.dart';
import '../presentation/driver_active_trip_screen/driver_active_trip_screen.dart';
import '../presentation/driver_trip_history_screen/driver_trip_history_screen.dart';
import '../presentation/busminder_attendance_screen/busminder_attendance_screen/busminder_attendance_screen.dart';
import '../presentation/busminder_trip_progress_screen/busminder_trip_progress_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String driverStartShift = '/driver-start-shift-screen';
  static const String sharedLogin = '/shared-login-screen';
  static const String driverActiveTrip = '/driver-active-trip-screen';
  static const String driverTripHistory = '/driver-trip-history-screen';
  static const String busminderAttendance = '/busminder-attendance-screen';
  static const String busminderTripProgress = '/busminder-trip-progress-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SharedLoginScreen(),
    driverStartShift: (context) => const DriverStartShiftScreen(),
    sharedLogin: (context) => const SharedLoginScreen(),
    driverActiveTrip: (context) => const DriverActiveTripScreen(),
    driverTripHistory: (context) => const DriverTripHistoryScreen(),
    busminderAttendance: (context) => const BusminderAttendanceScreen(),
    busminderTripProgress: (context) => const BusminderTripProgressScreen(),
    // TODO: Add your other routes here
  };
}
