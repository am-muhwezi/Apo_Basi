import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'services/notification_service.dart';
import 'services/bus_websocket_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the app IMMEDIATELY to avoid splash freeze
  runApp(MyApp());

  // Load .env in background (non-blocking)
  unawaited(dotenv.load());

  // Initialize notifications (non-blocking)
  unawaited(NotificationService().initialize());

  // Lock orientation (non-blocking)
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );

  // Custom error widget (non-blocking)
  _setupErrorWidget();
}

void _setupErrorWidget() {
  bool _hasShownError = false;

  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BusWebSocketService _webSocketService = BusWebSocketService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _tripStartSubscription;

  @override
  void initState() {
    super.initState();

    // Delay WebSocket initialization until the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _webSocketService.connect();
      // Note: Trip notifications will be handled via Django Channels in the future
      // For now, the connection is initialized for location tracking
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
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}
