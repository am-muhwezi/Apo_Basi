import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/app_logo_widget.dart';
import './widgets/login_form_widget.dart';

class SharedLoginScreen extends StatefulWidget {
  const SharedLoginScreen({super.key});

  @override
  State<SharedLoginScreen> createState() => _SharedLoginScreenState();
}

class _SharedLoginScreenState extends State<SharedLoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLastUsedId();
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

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  Future<void> _loadLastUsedId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString('last_user_id');
      if (lastId != null && mounted) {
        // Auto-fill last used ID for convenience
        setState(() {
          // Could auto-fill the form here if needed
        });
      }
    } catch (e) {
      // Silent fail - not critical functionality
    }
  }

  Future<void> _saveLastUsedId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_user_id', id);
    } catch (e) {
      // Silent fail - not critical functionality
    }
  }

  Future<void> _handleLogin(String phoneNumber) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    try {
      Map<String, dynamic>? response;
      String role;
      String route;

      // Try driver login first, then bus minder if it fails
      try {
        response = await _apiService.driverPhoneLogin(phoneNumber);
        role = 'driver';
        route = '/driver-start-shift-screen';
      } catch (driverError) {
        // Not a driver, try bus minder
        try {
          response = await _apiService.busMinderPhoneLogin(phoneNumber);
          role = 'busminder';
          route = '/busminder-start-shift-screen';
        } catch (busMinderError) {
          // Neither worked
          throw Exception('Phone number not registered. Please contact admin.');
        }
      }

      // Save successful login
      await _saveLastUsedId(phoneNumber);

      // Store user session (already saved in API service)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phoneNumber);

      // Cache bus and route data from login response for faster app startup
      if (role == 'driver' && response != null) {
        if (response['bus'] != null) {
          await prefs.setString('cached_bus_data', jsonEncode(response['bus']));
        }
        if (response['route'] != null) {
          await prefs.setString(
              'cached_route_data', jsonEncode(response['route']));
        }
      }

      // Success haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate based on role
        Navigator.pushReplacementNamed(context, route);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
                    SizedBox(height: 5.h),

                    // App Logo Section
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const AppLogoWidget(),
                    ),

                    SizedBox(height: 4.h),

                    // Login Form Section
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: LoginFormWidget(
                          onLogin: _handleLogin,
                          isLoading: _isLoading,
                          errorMessage: _errorMessage,
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Footer Information
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 85.w,
                        padding: EdgeInsets.all(4.w),
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
