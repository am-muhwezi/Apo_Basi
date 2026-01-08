import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file asynchronously in parallel with other initialization
  final envLoadingFuture = dotenv.load();

  // Initialize notification service asynchronously (non-blocking)
  NotificationService().initialize().catchError((error) {
    print('Error initializing notifications: $error');
  });

  // Wait for .env to load before starting app
  await envLoadingFuture;

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SocketService _socketService = SocketService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _tripStartSubscription;

  @override
  void initState() {
    super.initState();
    // Setup notifications asynchronously to avoid blocking UI
    Future.microtask(() => _setupTripNotifications());
  }

  /// Setup listener for trip start notifications
  void _setupTripNotifications() {
    _tripStartSubscription = _socketService.tripStartedStream.listen((data) {
      final busId = data['busId'] as int?;
      final busNumber = data['busNumber'] as String? ?? 'Unknown';
      final tripType = data['tripType'] as String? ?? 'Trip';

      _notificationService.showTripStartNotification(
        busNumber: busNumber,
        tripType: tripType,
        busId: busId ?? 0,
      );
    });
  }

  @override
  void dispose() {
    _tripStartSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'ApoBasi',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}
