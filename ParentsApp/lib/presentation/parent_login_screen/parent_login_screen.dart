import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/welcome_header_widget.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _magicLinkSent = false;
  String? _emailError;
  bool _isEmailValid = false;
  StreamSubscription<AuthResult>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _listenForAuthCallback();
    _checkAuthAndAutoNavigate();
  }

  /// Check if user is already authenticated and auto-navigate to dashboard
  Future<void> _checkAuthAndAutoNavigate() async {
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated && mounted) {
      // User already logged in - go straight to dashboard like Uber
      Navigator.pushReplacementNamed(context, '/parent-dashboard');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = null;
        _isEmailValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
        _isEmailValid = false;
      } else {
        _emailError = null;
        _isEmailValid = true;
      }
    });
  }

  void _listenForAuthCallback() {
    _authSubscription = _authService.listenForAuthCallback().listen((result) {
      if (result.success) {
        HapticFeedback.selectionClick();

        final firstName = result.parent?['firstName'] ?? 'Parent';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $firstName!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacementNamed(context, '/parent-dashboard');
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

  Future<void> _handleSendMagicLink() async {
    if (!_isEmailValid) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    HapticFeedback.lightImpact();

    try {
      final email = _emailController.text.trim();
      final result = await _authService.sendMagicLink(email);

      if (result['success']) {
        setState(() {
          _magicLinkSent = true;
          _isLoading = false;
        });

        HapticFeedback.selectionClick();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Magic link sent! Check your email.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _emailError = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _emailError = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Color(0xFFF8FAFC),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Welcome Header
              WelcomeHeaderWidget(),

              // Login Form
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 1.h),

                    // Email Input or Magic Link Sent Message
                    if (_magicLinkSent) ...[
                      // Magic Link Sent State - Sleek & Compact
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green.shade900.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.green.shade700.withValues(alpha: 0.4)
                                : Colors.green.shade700.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.mark_email_read_rounded,
                              size: 36,
                              color: Colors.green.shade600,
                            ),
                            SizedBox(height: 1.5.h),
                            Text(
                              'Check your email',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.green.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              _emailController.text.trim(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Click the link in your email to sign in.\nThe link expires in 1 hour.',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isDark ? Colors.grey.shade400 : Colors.green.shade600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _magicLinkSent = false;
                          });
                        },
                        icon: Icon(Icons.edit, size: 16),
                        label: Text(
                          'Use a different email',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryLight,
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                      ),
                    ] else ...[
                      // Email Input State
                      Text(
                        'Email Address',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.grey.shade700,
                                ),
                      ),
                      SizedBox(height: 1.h),
                      _buildEmailInput(),

                      // Error Message (if any)
                      if (_emailError != null) ...[
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.red.shade900.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.shade700,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 18,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  _emailError!,
                                  style: TextStyle(
                                    color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 2.5.h),

                      // Send Login Link Button
                      _buildSendLinkButton(),
                    ],

                    SizedBox(height: 3.h),

                    // Footer
                    Center(
                      child: Text(
                        '© 2026 ApoBasi - Powered by SoG',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 10.sp,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _emailError != null
              ? Colors.red.shade700
              : _isEmailValid
                  ? AppTheme.primaryLight
                  : isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
          width: _emailError != null || _isEmailValid ? 2 : 1.5,
        ),
        color: isDark ? Colors.grey.shade900 : Colors.white,
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: [AutofillHints.email],
        style: TextStyle(
          fontSize: 13.sp,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'your.email@example.com',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            fontSize: 13.sp,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
          border: InputBorder.none,
          suffixIcon: _isEmailValid
              ? Icon(Icons.check_circle, color: Colors.green, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildSendLinkButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton.icon(
      onPressed: _isEmailValid && !_isLoading ? _handleSendMagicLink : null,
      icon: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(Icons.email_outlined, size: 20),
      label: Text(
        _isLoading ? 'Sending...' : 'Send Login Link',
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isEmailValid && !_isLoading
            ? AppTheme.primaryLight
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        foregroundColor: _isEmailValid && !_isLoading
            ? Colors.white
            : (isDark ? Colors.grey.shade600 : Colors.grey.shade500),
        padding: EdgeInsets.symmetric(vertical: 1.8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: _isEmailValid && !_isLoading ? 2 : 0,
      ),
    );
  }
}
