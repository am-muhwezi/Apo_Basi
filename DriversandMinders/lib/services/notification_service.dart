import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for showing system (OS-level) notifications.
///
/// Used to notify drivers/minders when a trip starts or ends, even when the
/// app is in the background.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Wire this into MaterialApp.navigatorKey so that notification taps can
  /// navigate without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification IDs
  // NOTE: ID 1 is reserved by the native LocationTrackingService foreground
  // notification. Do NOT use ID 1 here — it would overwrite the foreground
  // service notification with a dismissable one.
  static const int _tripEndedId = 2;
  static const int _ongoingAttendanceId = 10;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Tapping the persistent attendance notification navigates back to
        // the active trip screen so the minder can quickly mark attendance.
        if (response.payload == 'attendance_ongoing') {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/busminder-active-trip-screen',
            (route) => false,
          );
        }
      },
    );
    _initialized = true;
  }

  /// Shown when a driver/minder ends a trip — dismissable completion alert.
  /// The persistent "trip active" notification is owned by the native
  /// LocationTrackingService foreground service (ID 1) and is automatically
  /// removed when stopLocationTracking() is called.
  Future<void> showTripEnded({
    required String busNumber,
    required String tripType,
  }) async {
    await init();
    final tripLabel = tripType == 'pickup' ? 'Pickup' : 'Dropoff';
    await _plugin.show(
      id: _tripEndedId,
      title: 'Trip Completed — $tripLabel',
      body: 'Bus $busNumber trip has ended.',
      notificationDetails: _alertNotificationDetails(),
    );
  }

  /// Persistent notification shown while the minder is recording attendance.
  /// Stays in the panel until [clearAttendanceNotification] is called.
  /// Tap navigates directly to the active trip screen.
  Future<void> showAttendanceOngoing({
    required String busNumber,
    required String tripType,
  }) async {
    await init();
    final tripLabel = tripType == 'pickup' ? 'Pickup' : 'Drop-off';
    const android = AndroidNotificationDetails(
      'apobasi_attendance_ongoing',
      'Active Attendance',
      channelDescription: 'Persistent notification while recording attendance',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      // Silent — this is a status indicator, not an alert
      enableVibration: false,
      playSound: false,
      // ApoBasi brand teal
      color: Color(0xFF00695C),
    );
    const ios = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    await _plugin.show(
      id: _ongoingAttendanceId,
      title: 'Attendance in Progress — $tripLabel',
      body: 'Bus $busNumber · Tap to mark student attendance',
      notificationDetails: const NotificationDetails(android: android, iOS: ios),
      payload: 'attendance_ongoing',
    );
  }

  /// Removes the persistent attendance notification when the shift ends.
  Future<void> clearAttendanceNotification() async {
    await init();
    await _plugin.cancel(id: _ongoingAttendanceId);
  }

  NotificationDetails _alertNotificationDetails() {
    const android = AndroidNotificationDetails(
      'apobasi_trips',
      'Trip Updates',
      channelDescription: 'Notifications for trip start and end events',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // ApoBasi brand teal background on the notification icon chip
      color: Color(0xFF00695C),
      enableVibration: true,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }
}
