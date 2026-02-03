import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../models/child_model.dart';
import './widgets/sign_in_button_widget.dart';
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

  /// Listen for authentication callback from magic link
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

        // Navigate to dashboard
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
        // Email not registered or other error
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
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Email Input or Magic Link Sent Message
                    if (_magicLinkSent) ...[
                      // Magic Link Sent State
                      Container(
                        padding: EdgeInsets.all(3.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.green.shade900.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.green.shade700
                                : Colors.green.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 60,
                              color: Colors.green,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Check your email',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade900,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'We sent a magic link to\n${_emailController.text.trim()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Click the link in your email to sign in. The link will expire in 1 hour.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _magicLinkSent = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryLight,
                            backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                          ),
                          child: Text(
                            'Use a different email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Email Input State
                      Text(
                        'Email Address',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      SizedBox(height: 1.h),
                      _buildEmailInput(),

                      SizedBox(height: 3.h),

                      // Send Magic Link Button
                      SignInButtonWidget(
                        isEnabled: _isEmailValid,
                        isLoading: _isLoading,
                        onPressed: _handleSendMagicLink,
                        buttonText: 'Send Magic Link',
                      ),
                    ],

                    SizedBox(height: 4.h),

                    // Footer
                    Center(
                      child: Text(
                        '© 2026 ApoBasi - Powered by SoG',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
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
              ? Colors.red
              : _isEmailValid
                  ? AppTheme.primaryLight
                  : isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
          width: _isEmailValid ? 2 : 1.5,
        ),
        color: isDark ? Colors.grey.shade900 : Colors.white,
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: [AutofillHints.email],
        decoration: InputDecoration(
          hintText: 'your.email@example.com',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixIcon: _isEmailValid
              ? Icon(Icons.check_circle, color: Colors.green)
              : null,
          errorText: _emailError,
          errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
