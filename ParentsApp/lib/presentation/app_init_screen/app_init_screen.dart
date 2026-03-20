import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

/// AppInitScreen — fast initialization gateway
///
/// Purpose:
///   Replace the `await Supabase.initialize()` call that was blocking
///   `runApp()` in main.dart. By moving Supabase init here we can show
///   branded UI (first frame) IMMEDIATELY while the SDK handshakes
///   in the background, saving ~300–800 ms of black-screen time.
///
/// Flow:
///   1. first frame: logo + spinner visible instantly
///   2. parallel:  Supabase.initialize() + SharedPreferences token check
///   3. navigate:  → /parent-dashboard  (token found)
///                → /parent-login-screen (no token)
class AppInitScreen extends StatefulWidget {
  const AppInitScreen({Key? key}) : super(key: key);

  @override
  State<AppInitScreen> createState() => _AppInitScreenState();
}

class _AppInitScreenState extends State<AppInitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    // Run all heavy work off the critical path.
    _initialize();
  }

  Future<void> _initialize() async {
    final results = await Future.wait([
      _initSupabase(),
      _checkToken(),
      // Minimum display time so the branded splash doesn't flash.
      Future.delayed(const Duration(milliseconds: 700)),
    ]);

    if (!mounted) return;

    final bool isAuthenticated = results[1] as bool;
    Navigator.pushReplacementNamed(
      context,
      isAuthenticated ? '/parent-dashboard' : '/parent-login-screen',
    );
  }

  /// Initialize Supabase SDK.
  /// Safely handles hot-restart where Supabase is already initialized.
  Future<void> _initSupabase() async {
    try {
      // If already initialized (hot-restart), this won't throw.
      Supabase.instance.client;
    } catch (_) {
      // Not initialized yet — run the full init.
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabasePublishableKey,
      );
    }
  }

  /// Check whether the user already has a valid Django JWT stored.
  Future<bool> _checkToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      return token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001c3f), // brand navy
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App logo
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/apobasi_logo_1024.png',
                  width: 110,
                  height: 110,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_bus,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'ApoBasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Smart School Transport',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 52),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
