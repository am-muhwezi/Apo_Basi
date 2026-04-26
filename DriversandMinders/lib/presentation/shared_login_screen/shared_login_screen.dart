import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/app_store.dart';
import '../../services/auth_service.dart';
import './widgets/app_logo_widget.dart';
import './widgets/login_form_widget.dart';

class SharedLoginScreen extends StatefulWidget {
  const SharedLoginScreen({super.key});

  @override
  State<SharedLoginScreen> createState() => _SharedLoginScreenState();
}

class _SharedLoginScreenState extends State<SharedLoginScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _magicLinkSent = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  StreamSubscription<AuthResult>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenForAuthCallback();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthAndAutoNavigate());
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  Future<void> _checkAuthAndAutoNavigate() async {
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getInt('driver_id');
      if (driverId != null) {
        Navigator.pushReplacementNamed(context, '/driver-start-shift-screen');
      }
    }
  }

  void _listenForAuthCallback() {
    _authSubscription = _authService.listenForAuthCallback().listen((result) {
      if (!mounted) return;
      if (result.success) {
        HapticFeedback.selectionClick();
        final userName = result.driver?['name'] ?? 'Driver';
        String route = '/driver-start-shift-screen';
        if (result.bus != null) {
          _cacheDriverData(result);
        } else if (result.route != null && result.route!['buses'] != null) {
          route = '/busminder-start-shift-screen';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Welcome back, $userName!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
        Navigator.pushReplacementNamed(context, route);
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.error ?? 'Authentication failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
        setState(() {
          _magicLinkSent = false;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _cacheDriverData(AuthResult result) async {
    try {
      await AppStore.instance.saveBusCache(result.bus, result.route);
    } catch (_) {}
  }

  Future<void> _handleSendMagicLink(String email) async {
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorMessage = null; });
    HapticFeedback.lightImpact();

    try {
      final result = await _authService.sendMagicLink(email);
      if (!mounted) return;
      if (result['success']) {
        HapticFeedback.selectionClick();
        setState(() { _magicLinkSent = true; _isLoading = false; });
      } else {
        HapticFeedback.heavyImpact();
        setState(() { _errorMessage = result['message']; _isLoading = false; });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _handlePasswordLogin(String email, String password) async {
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final result = await _authService.loginWithPassword(email, password);
      if (!mounted) return;
      if (result.success) {
        HapticFeedback.selectionClick();
        final userName = result.driver?['name'] ?? 'Driver';
        String route = '/driver-start-shift-screen';
        if (result.bus != null) {
          _cacheDriverData(result);
        } else if (result.route != null && result.route!['buses'] != null) {
          route = '/busminder-start-shift-screen';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Welcome, $userName!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
        Navigator.pushReplacementNamed(context, route);
      } else {
        HapticFeedback.heavyImpact();
        setState(() { _errorMessage = result.error ?? 'Login failed'; _isLoading = false; });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() { _errorMessage = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surface.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 4.h),

                    RepaintBoundary(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: const AppLogoWidget(),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: LoginFormWidget(
                          onLogin: _handleSendMagicLink,
                          onPasswordLogin: _handlePasswordLogin,
                          isLoading: _isLoading,
                          magicLinkSent: _magicLinkSent,
                          errorMessage: _errorMessage,
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        '© 2026 ApoBasi - Powered by SoG',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
