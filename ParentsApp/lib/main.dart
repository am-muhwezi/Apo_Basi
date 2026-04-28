import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/app_export.dart';
import 'config/api_config.dart';
import 'widgets/custom_error_widget.dart';
import 'services/notification_service.dart';
import 'services/bus_websocket_service.dart';
import 'services/parent_notifications_service.dart';
import 'services/theme_service.dart';
import 'services/home_location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env before starting the app - explicitly specify the file name
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env file loaded successfully');
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    // In release builds, continue anyway - we'll handle missing values later
  }

  // Print API configuration for debugging
  ApiConfig.printConfigSummary();

  // Validate required configuration
  if (!ApiConfig.validateConfig()) {
    print('⚠️ WARNING: Missing required API configuration!');
    print('   API_BASE_URL: ${ApiConfig.apiBaseUrl.isEmpty ? "MISSING" : "OK"}');
    print('   MAPBOX_ACCESS_TOKEN: ${ApiConfig.mapboxAccessToken.isEmpty ? "MISSING" : "OK"}');
  }

  // Initialize Mapbox access token (synchronous — fast)
  MapboxOptions.setAccessToken(ApiConfig.mapboxAccessToken);

  // Initialize theme service — single SharedPreferences read, very fast.
  await ThemeService().initialize();

  // Give the notification service a navigator key so tapping any notification
  // opens the notifications page, regardless of which screen is active.
  final navKey = GlobalKey<NavigatorState>();
  NotificationService().navigatorKey = navKey;

  // NOTE: Supabase.initialize() has been moved into AppInitScreen so that
  // runApp() is no longer blocked by the network SDK handshake (~300-800 ms).
  // AppInitScreen shows branded UI while init runs, then routes to dashboard
  // or login depending on whether a stored JWT token is found.

  runApp(MyApp());

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

      Future.delayed(const Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BusWebSocketService _webSocketService = BusWebSocketService();
  final ParentNotificationsService _notificationsService =
      ParentNotificationsService();
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();

    // Delay heavy initialization until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Request location permission on first run
      final locationStatus = await Permission.locationWhenInUse.status;
      if (locationStatus.isDenied) {
        await Permission.locationWhenInUse.request();
      }

      // Delay WebSocket connection even further to improve startup
      Future.delayed(const Duration(milliseconds: 500), () {
        _webSocketService.connect();
        _notificationsService.connect();
        // Migrate any existing home coords from SharedPreferences to the backend DB
        HomeLocationService().syncOnStartup();
      });
    });
  }

  @override
  void dispose() {
    _notificationsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: _themeService.themeModeNotifier,
          builder: (context, themeMode, _) {
            // Only MaterialApp rebuilds, not entire widget tree
            return MaterialApp(
              navigatorKey: NotificationService().navigatorKey,
              title: 'ApoBasi',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              themeAnimationDuration: Duration.zero,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child!,
                );
              },
              debugShowCheckedModeBanner: false,
              routes: AppRoutes.routes,
              initialRoute: AppRoutes.initial,
            );
          },
        );
      },
    );
  }
}
