import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import 'config/api_config.dart';
import 'services/app_store.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (cached after first load)
  await dotenv.load();

  // Initialize Mapbox SDK with access token (mobile only — not supported on desktop)
  if (Platform.isAndroid || Platform.isIOS) {
    MapboxOptions.setAccessToken(ApiConfig.mapboxAccessToken);
  }

  // Initialize Supabase for magic link authentication
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabasePublishableKey,
  );

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

  // Initialize AppStore (in-memory state backed by SharedPreferences)
  await AppStore.initialize();

  // Initialize theme service so saved preference is loaded before first frame
  await ThemeService().initialize();

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(MyApp());

    // Request location permission after first frame (mobile only)
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final whenInUseStatus = await Permission.locationWhenInUse.status;
        if (whenInUseStatus.isDenied) {
          await Permission.locationWhenInUse.request();
        }
        final alwaysStatus = await Permission.locationAlways.status;
        if (alwaysStatus.isDenied) {
          await Permission.locationAlways.request();
        }
      });
    }
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeService().themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'Basi Driver',
            theme: AppTheme.lightDriverTheme,
            darkTheme: AppTheme.darkDriverTheme,
            themeMode: themeMode,
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
        },
      );
    });
  }
}
