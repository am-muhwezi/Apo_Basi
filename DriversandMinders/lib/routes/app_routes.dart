import 'package:flutter/material.dart';
import '../presentation/children_map_screen/children_map_screen.dart';
import '../presentation/driver_start_shift_screen/driver_start_shift_screen.dart';
import '../presentation/shared_login_screen/shared_login_screen.dart';
import '../presentation/driver_active_trip_screen/driver_active_trip_screen.dart';
import '../presentation/driver_trip_history_screen/driver_trip_history_screen.dart';
import '../presentation/driver_profile_screen/driver_profile_screen.dart';
import '../presentation/driver_settings_screen/driver_settings_screen.dart';
import '../presentation/driver_comms_screen/driver_comms_screen.dart';
import '../presentation/busminder_start_shift_screen/busminder_start_shift_screen.dart';
import '../presentation/busminder_attendance_screen/busminder_attendance_screen/busminder_attendance_screen.dart';
import '../presentation/busminder_trip_progress_screen/busminder_trip_progress_screen.dart';
import '../presentation/busminder_active_trip_screen/busminder_active_trip_screen.dart';
import '../presentation/busminder_trip_history_screen/busminder_trip_history_screen.dart';
import '../presentation/busminder_profile_screen/busminder_profile_screen.dart';
import '../presentation/busminder_settings_screen/busminder_settings_screen.dart';
import '../presentation/busminder_communications_screen/busminder_communications_screen.dart';

class AppRoutes {
  // Routes
  static const String initial = '/';
  static const String sharedLogin = '/shared-login-screen';

  // Driver routes
  static const String childrenMap = '/children-map-screen';
  static const String driverStartShift = '/driver-start-shift-screen';
  static const String driverActiveTrip = '/driver-active-trip-screen';
  static const String driverTripHistory = '/driver-trip-history-screen';
  static const String driverProfile = '/driver-profile-screen';
  static const String driverSettings = '/driver-settings-screen';
  static const String driverComms = '/driver-comms-screen';

  // Busminder routes
  static const String busminderStartShift = '/busminder-start-shift-screen';
  static const String busminderActiveTrip = '/busminder-active-trip-screen';
  static const String busminderAttendance = '/busminder-attendance-screen';
  static const String busminderTripProgress = '/busminder-trip-progress-screen';
  static const String busminderTripHistory = '/busminder-trip-history-screen';
  static const String busminderProfile = '/busminder-profile';
  static const String busminderSettings = '/busminder-settings';
  static const String busminderCommunications = '/busminder-communications';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SharedLoginScreen(),
    sharedLogin: (context) => const SharedLoginScreen(),
    childrenMap: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ChildrenMapScreen(
        students: List<Map<String, dynamic>>.from(args['students'] as List),
        tripData: Map<String, dynamic>.from(args['tripData'] as Map),
      );
    },
    driverStartShift: (context) => const DriverStartShiftScreen(),
    driverActiveTrip: (context) => const DriverActiveTripScreen(),
    driverTripHistory: (context) => const DriverTripHistoryScreen(),
    driverProfile: (context) => const DriverProfileScreen(),
    driverSettings: (context) => const DriverSettingsScreen(),
    driverComms: (context) => const DriverCommsScreen(),
    busminderStartShift: (context) => const BusminderStartShiftScreen(),
    busminderActiveTrip: (context) => const BusminderActiveTripScreen(),
    busminderAttendance: (context) => const BusminderAttendanceScreen(),
    busminderTripProgress: (context) => const BusminderTripProgressScreen(),
    busminderTripHistory: (context) => const BusMinderTripHistoryScreen(),
    busminderProfile: (context) => const BusminderProfileScreen(),
    busminderSettings: (context) => const BusminderSettingsScreen(),
    busminderCommunications: (context) => const BusminderCommunicationsScreen(),
  };
}
