import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import 'routes/app_routes.dart';
import 'services/app_store.dart';
import 'services/theme_service.dart';

// Flips to true once AppStore + ThemeService are ready (~150ms).
// _BootApp's builder swaps the splash body for the real navigator.
final ValueNotifier<bool> _appReadyNotifier = ValueNotifier(false);

// Flips to true once Supabase.initialize() completes (network-bound, ~5-10s).
// SharedLoginScreen uses this to defer its auth subscription safely.
final ValueNotifier<bool> supabaseReadyNotifier = ValueNotifier(false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // dotenv MUST finish before runApp — MapboxOptions needs the token.
  await dotenv.load();

  if (Platform.isAndroid || Platform.isIOS) {
    MapboxOptions.setAccessToken(ApiConfig.mapboxAccessToken);
  }

  // Orientation lock — fire-and-forget, no need to await before showing UI.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ignore: prefer_final_locals
  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // Show branded splash immediately — user sees the app within ~200ms.
  runApp(const _BootApp());

  // Supabase makes network calls and occupies the Dart isolate for several
  // seconds. Fire it completely in background — the login screen defers its
  // auth subscription until supabaseReadyNotifier fires.
  unawaited(
    Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabasePublishableKey,
    ).then((_) => supabaseReadyNotifier.value = true),
  );

  // AppStore + ThemeService are pure SharedPreferences reads — ~150ms total.
  // Flip to real app the moment they finish.
  await Future.wait([
    AppStore.initialize(),
    ThemeService().initialize(),
  ]);

  _appReadyNotifier.value = true;
}

// ── Single-MaterialApp boot wrapper ─────────────────────────────────────────
// One MaterialApp lives for the entire app lifetime. The builder callback
// shows _SplashBody while AppStore/ThemeService init (~150ms), then hands
// off to the real navigator — no second MaterialApp construction on transition.

class _BootApp extends StatelessWidget {
  const _BootApp();

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
              return ValueListenableBuilder<bool>(
                valueListenable: _appReadyNotifier,
                builder: (_, ready, __) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(1.0),
                  ),
                  child: ready ? child! : const _SplashBody(),
                ),
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

// Splash body — plain Scaffold, no MaterialApp wrapper.
// Lives inside the single MaterialApp above; hardcoded colors are intentional
// so it renders correctly before ThemeService has loaded the user's preference.
class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/img_app_logo.svg',
              width: 88,
              height: 88,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
