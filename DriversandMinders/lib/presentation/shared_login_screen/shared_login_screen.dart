import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  // Mock credentials for demo
  final Map<String, Map<String, dynamic>> _mockCredentials = {
    'D1234': {
      'role': 'driver',
      'name': 'John Smith',
      'route': '/driver-start-shift-screen',
    },
    'D5678': {
      'role': 'driver',
      'name': 'Mike Johnson',
      'route': '/driver-start-shift-screen',
    },
    'S1234': {
      'role': 'busminder',
      'name': 'Sarah Wilson',
      'route': '/busminder-attendance-screen',
    },
    'S5678': {
      'role': 'busminder',
      'name': 'Emily Davis',
      'route': '/busminder-attendance-screen',
    },
  };

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

  Future<void> _handleLogin(String id) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check mock credentials
      final userCredentials = _mockCredentials[id];

      if (userCredentials == null) {
        setState(() {
          _errorMessage =
              'Invalid credentials. Please check your ID and try again.';
          _isLoading = false;
        });
        HapticFeedback.heavyImpact();
        return;
      }

      // Save successful login
      await _saveLastUsedId(id);

      // Store user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', userCredentials['role']);
      await prefs.setString('user_name', userCredentials['name']);
      await prefs.setString('user_id', id);
      await prefs.setBool('is_logged_in', true);

      // Success haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        // Navigate based on role
        Navigator.pushReplacementNamed(
          context,
          userCredentials['route'],
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
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
                            // Demo Credentials Info
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'info_outline',
                                        color: colorScheme.primary,
                                        size: 18,
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        'Demo Credentials',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'Drivers: D1234, D5678\nStaff: S1234, S5678',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 3.h),

                            // Copyright
                            Text(
                              '© 2024 BusTracker Pro. All rights reserved.',
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
