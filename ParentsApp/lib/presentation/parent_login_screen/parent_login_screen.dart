import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _magicLinkSent = false;
  String? _emailError;
  String? _passwordError;
  bool _isEmailValid = false;
  bool _isReviewerAccount = false;
  bool _obscurePassword = true;

  // Debounce timer — prevents setState on every keystroke
  Timer? _debounce;
  final FocusNode _emailFocusNode = FocusNode();

  StreamSubscription<AuthResult>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _emailFocusNode.addListener(_onEmailFocusChanged);
    _listenForAuthCallback();
    _checkAuthAndAutoNavigate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndAutoNavigate() async {
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated && mounted) {
      Navigator.pushReplacementNamed(context, '/parent-dashboard');
    }
  }

  // Debounce: only validate after 250ms of no typing
  void _onEmailChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _validateEmail);
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = null;
        _isEmailValid = false;
        _isReviewerAccount = false;
      });
      return;
    }
    final valid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    setState(() {
      // Clear error as soon as the email becomes valid; never add it here.
      if (valid) _emailError = null;
      _isEmailValid = valid;
      _isReviewerAccount = valid && AuthService.isReviewerAccount(email);
    });
  }

  // Show error only when the field loses focus with an incomplete address.
  void _onEmailFocusChanged() {
    if (!_emailFocusNode.hasFocus && !_isEmailValid && _emailController.text.trim().isNotEmpty) {
      if (mounted) setState(() => _emailError = 'Please enter a valid email address');
    }
  }

  void _listenForAuthCallback() {
    _authSubscription = _authService.listenForAuthCallback().listen((result) {
      if (!mounted) return;
      if (result.success) {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Welcome back, ${result.parent?['firstName'] ?? 'Parent'}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
        Navigator.pushReplacementNamed(context, '/parent-dashboard');
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

  Future<void> _handleSendMagicLink() async {
    if (!_isEmailValid) {
      setState(() => _emailError = 'Please enter a valid email address');
      return;
    }
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _emailError = null; });
    HapticFeedback.lightImpact();

    try {
      final result = await _authService.sendMagicLink(_emailController.text.trim());
      if (!mounted) return;
      if (result['success']) {
        HapticFeedback.selectionClick();
        setState(() { _magicLinkSent = true; _isLoading = false; });
      } else {
        HapticFeedback.heavyImpact();
        setState(() { _emailError = result['message']; _isLoading = false; });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() { _emailError = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _handlePasswordLogin() async {
    if (!_isEmailValid || !_isReviewerAccount || _isLoading) return;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter password');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _passwordError = null; });
    HapticFeedback.lightImpact();

    try {
      final result = await _authService.loginWithPassword(
        _emailController.text.trim(), password);
      if (!mounted) return;
      if (result.success) {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Welcome, ${result.parent?['firstName'] ?? 'Reviewer'}!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
        Navigator.pushReplacementNamed(context, '/parent-dashboard');
      } else {
        HapticFeedback.heavyImpact();
        setState(() { _passwordError = result.error ?? 'Login failed'; _isLoading = false; });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() { _passwordError = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Single Theme lookup for the entire build — not repeated inside every helper
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // RepaintBoundary: header never needs to repaint when form changes
              const RepaintBoundary(child: WelcomeHeaderWidget()),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    if (_magicLinkSent)
                      _buildMagicLinkSentCard(isDark)
                    else
                      _buildForm(isDark),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        '© 2026 ApoBasi - Powered by SoG',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Email Address',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _buildEmailInput(isDark),

        if (_emailError != null) ...[
          const SizedBox(height: 8),
          _buildErrorRow(_emailError!, isDark),
        ],

        if (_isReviewerAccount) ...[
          const SizedBox(height: 16),
          Text(
            'Password',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          _buildPasswordInput(isDark),
          if (_passwordError != null) ...[
            const SizedBox(height: 8),
            Text(
              _passwordError!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],

        const SizedBox(height: 20),

        // ValueListenableBuilder: only the button area rebuilds when password
        // text changes, not the entire screen
        _isReviewerAccount
            ? ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordController,
                builder: (_, value, __) =>
                    _buildActionButton(isDark, isSignIn: true, hasPassword: value.text.isNotEmpty),
              )
            : _buildActionButton(isDark, isSignIn: false),
      ],
    );
  }

  Widget _buildMagicLinkSentCard(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.green.shade900.withValues(alpha: 0.15)
                : Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade700.withValues(alpha: isDark ? 0.4 : 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.mark_email_read_rounded, size: 36, color: Colors.green.shade600),
              const SizedBox(height: 12),
              Text(
                'Check your email',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.green.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _emailController.text.trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click the link in your email to sign in.\nThe link expires in 1 hour.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.green.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _magicLinkSent = false),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Use a different email', style: TextStyle(fontSize: 14)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInput(bool isDark) {
    final borderColor = _emailError != null
        ? Colors.red.shade700
        : _isEmailValid
            ? AppTheme.primaryLight
            : isDark
                ? Colors.grey.shade700
                : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: (_emailError != null || _isEmailValid) ? 2 : 1.5),
        color: isDark ? Colors.grey.shade900 : Colors.white,
      ),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'your.email@example.com',
          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixIcon: _isEmailValid ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null,
        ),
      ),
    );
  }

  Widget _buildPasswordInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _passwordError != null ? Colors.red.shade700 : isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: _passwordError != null ? 2 : 1.5,
        ),
        color: isDark ? Colors.grey.shade900 : Colors.white,
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorRow(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark, {required bool isSignIn, bool hasPassword = false}) {
    final enabled = _isEmailValid && !_isLoading && (!isSignIn || hasPassword);
    final bgColor = enabled ? AppTheme.primaryLight : (isDark ? Colors.grey.shade800 : Colors.grey.shade300);
    final fgColor = enabled ? Colors.white : (isDark ? Colors.grey.shade600 : Colors.grey.shade500);

    return ElevatedButton.icon(
      onPressed: enabled ? (isSignIn ? _handlePasswordLogin : _handleSendMagicLink) : null,
      icon: _isLoading
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
            )
          : Icon(isSignIn ? Icons.login_rounded : Icons.email_outlined, size: 20),
      label: Text(
        _isLoading
            ? (isSignIn ? 'Signing in...' : 'Sending...')
            : (isSignIn ? 'Sign In' : 'Send Login Link'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: enabled ? 2 : 0,
      ),
    );
  }
}
