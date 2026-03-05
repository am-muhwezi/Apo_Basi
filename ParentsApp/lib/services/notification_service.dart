import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request notification permission (required on Android 13+ and iOS)
    await Permission.notification.request();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap — navigate to notifications screen
      },
    );

    // Pre-create Android notification channels so they exist with the right
    // sound/vibration settings before any notification is shown.
    await _createChannels();

    _isInitialized = true;
  }

  Future<void> _createChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Trip alerts — highest priority, heads-up popup
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'trip_notifications',
        'Trip Alerts',
        description: 'Bus trip start and completion alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF001c3f),
        showBadge: true,
      ),
    );

    // Attendance alerts — also highest priority
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'attendance_notifications',
        'Attendance Alerts',
        description: 'Child pickup and drop-off alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF001c3f),
        showBadge: true,
      ),
    );
  }

  // Shared Android details that produce a heads-up popup, sound, and vibration
  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    required String ticker,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      ticker: ticker,
      importance: Importance.max,   // Importance.max = heads-up banner popup
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
      enableLights: true,
      ledColor: const Color(0xFF001c3f),
      ledOnMs: 500,
      ledOffMs: 1000,
      channelShowBadge: true,
      // Full-colour app icon shown in the notification drawer
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: const DefaultStyleInformation(true, true),
      autoCancel: true,
    );
  }

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  Future<void> showTripStartNotification({
    required String childName,
    required String busNumber,
    required String tripType,
    required int busId,
  }) async {
    await _ensureInitialized();

    await _plugin.show(
      busId,
      '$childName Pickup Trip Started',
      "$childName's bus has started the ${tripType.toLowerCase()} trip. "
          'The bus will be arriving shortly.',
      NotificationDetails(
        android: _androidDetails(
          channelId: 'trip_notifications',
          channelName: 'Trip Alerts',
          ticker: 'Bus trip started',
        ),
        iOS: _iosDetails,
      ),
      payload: 'trip_start:$busId',
    );
  }

  Future<void> showPickupNotification({
    required String childName,
    required String busNumber,
  }) async {
    await _ensureInitialized();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '$childName Picked Up',
      '$childName has been safely picked up by bus $busNumber',
      NotificationDetails(
        android: _androidDetails(
          channelId: 'attendance_notifications',
          channelName: 'Attendance Alerts',
          ticker: 'Child picked up',
        ),
        iOS: _iosDetails,
      ),
    );
  }

  Future<void> showDropoffNotification({
    required String childName,
    required String busNumber,
  }) async {
    await _ensureInitialized();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '$childName Dropped Off',
      '$childName has been safely dropped off by bus $busNumber',
      NotificationDetails(
        android: _androidDetails(
          channelId: 'attendance_notifications',
          channelName: 'Attendance Alerts',
          ticker: 'Child dropped off',
        ),
        iOS: _iosDetails,
      ),
    );
  }

  Future<void> showTripCompletedNotification({
    required String childName,
    required String busNumber,
    required String tripType,
    required int busId,
  }) async {
    await _ensureInitialized();

    final bool isPickup = tripType.toLowerCase() == 'pickup';

    await _plugin.show(
      busId,
      isPickup ? '$childName Reached School Safely' : 'Bus $busNumber Trip Completed',
      isPickup
          ? '$childName has arrived safely at school.'
          : 'The bus trip has been completed.',
      NotificationDetails(
        android: _androidDetails(
          channelId: 'trip_notifications',
          channelName: 'Trip Alerts',
          ticker: isPickup ? 'Child arrived at school' : 'Trip completed',
        ),
        iOS: _iosDetails,
      ),
    );
  }
}
