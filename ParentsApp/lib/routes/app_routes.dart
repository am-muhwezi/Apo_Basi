import 'package:flutter/material.dart';
import '../presentation/notifications_center/notifications_center.dart';
import '../presentation/parent_profile_settings/parent_profile_settings.dart';
import '../presentation/live_bus_tracking_map/live_bus_tracking_map.dart';
import '../presentation/parent_login_screen/parent_login_screen.dart';
import '../presentation/parent_dashboard/parent_dashboard.dart';

class AppRoutes {
  static const String initial = '/';
  static const String parentLogin = '/parent-login-screen';
  static const String parentDashboard = '/parent-dashboard';
  static const String liveBusTrackingMap = '/live-bus-tracking-map';
  static const String notificationsCenter = '/notifications-center';
  static const String parentProfileSettings = '/parent-profile-settings';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const ParentLoginScreen(),
    parentLogin: (context) => const ParentLoginScreen(),
    parentDashboard: (context) => const ParentDashboard(),
    liveBusTrackingMap: (context) => const LiveBusTrackingMap(),
    notificationsCenter: (context) => const NotificationsCenter(),
    parentProfileSettings: (context) => const ParentProfileSettings(),
  };
}
