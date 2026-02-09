import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/app_logo_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/phone_login_form_widget.dart';
import './widgets/login_method_toggle.dart';

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
  LoginMethod _selectedLoginMethod = LoginMethod.email;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _formSwitchController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _formFadeAnimation;
  StreamSubscription<AuthResult>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenForAuthCallback();
    _checkAuthAndAutoNavigate();
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

    _formSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formSwitchController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _formSwitchController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  /// Check if user is already authenticated and auto-navigate
  Future<void> _checkAuthAndAutoNavigate() async {
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated && mounted) {
      // Check which role based on stored data
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getInt('driver_id');

      if (driverId != null) {
        // User already logged in - go straight to appropriate screen
        Navigator.pushReplacementNamed(context, '/driver-start-shift-screen');
      }
    }
  }

  void _listenForAuthCallback() {
    _authSubscription = _authService.listenForAuthCallback().listen((result) {
      if (result.success) {
        HapticFeedback.selectionClick();

        // Determine role and route based on response data
        String route;
        String userName = 'User';

        if (result.driver != null) {
          userName = result.driver!['name'] ?? 'Driver';

          // Check if this is a driver or bus minder based on response
          if (result.bus != null) {
            // Has bus assignment - this is a driver
            route = '/driver-start-shift-screen';

            // Cache bus and route data for faster app startup
            _cacheDriverData(result);
          } else if (result.route != null && result.route!['buses'] != null) {
            // Has buses (plural) - this is a bus minder
            route = '/busminder-start-shift-screen';
          } else {
            // Default to driver screen
            route = '/driver-start-shift-screen';
          }
        } else {
          // Fallback
          route = '/driver-start-shift-screen';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $userName!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacementNamed(context, route);
      } else {
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Authentication failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        setState(() {
          _magicLinkSent = false;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _cacheDriverData(AuthResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (result.bus != null) {
        await prefs.setString('cached_bus_data', jsonEncode(result.bus));
      }
      if (result.route != null) {
        await prefs.setString('cached_route_data', jsonEncode(result.route));
      }
    } catch (e) {
      // Silent fail - not critical
    }
  }

  Future<void> _handleSendMagicLink(String email) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      final result = await _authService.sendMagicLink(email);

      if (result['success']) {
        setState(() {
          _magicLinkSent = true;
          _isLoading = false;
        });

        HapticFeedback.selectionClick();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Magic link sent! Check your email.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePhoneLogin(String phoneNumber) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      final result = await _authService.loginWithPhone(phoneNumber);

      if (result['success']) {
        HapticFeedback.selectionClick();

        final authResult = result['result'] as AuthResult;

        // Determine route based on assignment
        String route;
        String userName = 'User';

        if (authResult.driver != null) {
          userName = authResult.driver!['name'] ?? 'Driver';

          if (authResult.bus != null) {
            route = '/driver-start-shift-screen';
            _cacheDriverData(authResult);
          } else if (authResult.route != null && authResult.route!['buses'] != null) {
            route = '/busminder-start-shift-screen';
          } else {
            route = '/driver-start-shift-screen';
          }
        } else {
          route = '/driver-start-shift-screen';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $userName!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacementNamed(context, route);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _handleLoginMethodChange(LoginMethod method) {
    if (_selectedLoginMethod != method) {
      setState(() {
        _selectedLoginMethod = method;
        _errorMessage = null;
        _magicLinkSent = false;
      });

      // Animate form transition
      _formSwitchController.reset();
      _formSwitchController.forward();

      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _formSwitchController.dispose();
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
                    SizedBox(height: 3.h),

                    // App Logo Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const AppLogoWidget(),
                    ),

                    SizedBox(height: 2.5.h),

                    // Login Method Toggle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: LoginMethodToggle(
                        selectedMethod: _selectedLoginMethod,
                        onMethodChanged: _handleLoginMethodChange,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Login Form Section (switches between Email and Phone)
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _formFadeAnimation,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _selectedLoginMethod == LoginMethod.email
                              ? LoginFormWidget(
                                  key: const ValueKey('email_form'),
                                  onLogin: _handleSendMagicLink,
                                  isLoading: _isLoading,
                                  magicLinkSent: _magicLinkSent,
                                  errorMessage: _errorMessage,
                                )
                              : PhoneLoginFormWidget(
                                  key: const ValueKey('phone_form'),
                                  onLogin: _handlePhoneLogin,
                                  isLoading: _isLoading,
                                  errorMessage: _errorMessage,
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Footer Information
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 85.w,
                        padding: EdgeInsets.all(2.w),
                        child: Column(
                          children: [
                            // Copyright
                            Text(
                              '© 2026 ApoBasi - Powered by SoG',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 1.h),
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
