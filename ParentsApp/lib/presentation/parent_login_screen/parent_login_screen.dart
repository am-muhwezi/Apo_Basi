import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/welcome_header_widget.dart';

// Design tokens from the new brand system
const _kPrimary = Color(0xFF003282);
const _kPrimaryDark = Color(0xFF001B3D);
const _kSecondary = Color(0xFFFED01B);
const _kOnSecondary = Color(0xFF231B00);
const _kSurface = Color(0xFFF8F9FF);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kSurfaceContainerLow = Color(0xFFEFF4FF);
const _kOnSurface = Color(0xFF001B3D);
const _kOnSurfaceVariant = Color(0xFF434655);
const _kOutline = Color(0xFF737686);
const _kOutlineVariant = Color(0xFFC3C6D7);
const _kError = Color(0xFFBA1A1A);

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
      if (valid) _emailError = null;
      _isEmailValid = valid;
      _isReviewerAccount = valid && AuthService.isReviewerAccount(email);
    });
  }

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
          backgroundColor: _kError,
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
    final topPadding = MediaQuery.of(context).padding.top;
    // Hero background extends past the header into the card overlap zone
    final heroBgHeight = topPadding + 300.0;

    return Scaffold(
      backgroundColor: _kSurface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Gradient hero background
            _GradientHeroBackground(height: heroBgHeight),

            // Scrollable content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Hero content (logo + title + tagline)
                  const RepaintBoundary(child: WelcomeHeaderWidget()),

                  // Form card — overlaps gradient by ~56px
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: _magicLinkSent
                        ? _buildMagicLinkSentCard()
                        : _buildFormCard(),
                  ),

                  const SizedBox(height: 24),

                  // "Having trouble?" link
                  _buildTroubleLink(),

                  const SizedBox(height: 40),

                  // Footer
                  _buildFooter(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────── FORM CARD ───────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _kOnSurface.withValues(alpha: 0.10),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          Text(
            'Email',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildEmailInput(),

          if (_emailError != null) ...[
            const SizedBox(height: 8),
            _buildErrorRow(_emailError!),
          ],

          // Password field (reviewer accounts only)
          if (_isReviewerAccount) ...[
            const SizedBox(height: 20),
            Text(
              'Password',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildPasswordInput(),
            if (_passwordError != null) ...[
              const SizedBox(height: 8),
              _buildErrorRow(_passwordError!),
            ],
          ],

          const SizedBox(height: 24),

          // Action button
          _isReviewerAccount
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _passwordController,
                  builder: (_, value, __) =>
                      _buildActionButton(isSignIn: true, hasPassword: value.text.isNotEmpty),
                )
              : _buildActionButton(isSignIn: false),

          const SizedBox(height: 28),

          // Trust & Safety divider
          _buildTrustSection(),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: _emailError != null
            ? Border.all(color: _kError, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        style: GoogleFonts.inter(
          fontSize: 15,
          color: _kOnSurface,
        ),
        decoration: InputDecoration(
          hintText: 'e.g. parent@example.com',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: _kOutline,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          suffixIcon: _isEmailValid
              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF006242), size: 20)
              : Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.mail_outline_rounded,
                      color: _kPrimary.withValues(alpha: 0.4), size: 20),
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: _passwordError != null
            ? Border.all(color: _kError, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: GoogleFonts.inter(fontSize: 15, color: _kOnSurface),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.inter(fontSize: 15, color: _kOutline),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _kOutline,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required bool isSignIn, bool hasPassword = false}) {
    final enabled = _isEmailValid && !_isLoading && (!isSignIn || hasPassword);

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? (isSignIn ? _handlePasswordLogin : _handleSendMagicLink) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kSecondary,
            foregroundColor: _kOnSecondary,
            disabledBackgroundColor: _kSecondary,
            disabledForegroundColor: _kOnSecondary,
            elevation: enabled ? 4 : 0,
            shadowColor: _kSecondary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(_kOnSecondary),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSignIn ? 'Sign In' : 'Send Login Link',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kOnSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20, color: _kOnSecondary),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTrustSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: _kOutlineVariant.withValues(alpha: 0.5), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'TRUST & SAFETY',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kOutline,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            Expanded(child: Divider(color: _kOutlineVariant.withValues(alpha: 0.5), thickness: 1)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "We'll send a secure, one-time access link to your inbox. No passwords required.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: _kOnSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRow(String message) {
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, color: _kError, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _kError,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────── MAGIC LINK SENT STATE ───────────────────────────

  Widget _buildMagicLinkSentCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _kOnSurface.withValues(alpha: 0.10),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF006242).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                size: 32, color: Color(0xFF006242)),
          ),
          const SizedBox(height: 16),
          Text(
            'Check your email',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _emailController.text.trim(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF006242),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the link in your email to sign in.\nThe link expires in 1 hour.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _kOnSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => setState(() => _magicLinkSent = false),
            icon: const Icon(Icons.edit_outlined, size: 16, color: _kPrimary),
            label: Text(
              'Use a different email',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── BOTTOM SECTIONS ───────────────────────────────

  Widget _buildTroubleLink() {
    return TextButton.icon(
      onPressed: () => launchUrl(
        Uri.parse('mailto:hello@apobasi.com'),
        mode: LaunchMode.externalApplication,
      ),
      icon: const Icon(Icons.help_outline_rounded, size: 18, color: _kPrimary),
      label: Text(
        'Having trouble logging in?',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://www.apobasi.com/privacy'),
                  mode: LaunchMode.externalApplication),
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.inter(fontSize: 13, color: _kOutline),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: _kOutlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('https://www.apobasi.com/terms'),
                  mode: LaunchMode.externalApplication),
              child: Text(
                'Terms of Service',
                style: GoogleFonts.inter(fontSize: 13, color: _kOutline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© ${DateTime.now().year} ApoBasi. All rights reserved.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: _kOutline.withValues(alpha: 0.6),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────── GRADIENT HERO BACKGROUND ────────────────────────

class _GradientHeroBackground extends StatelessWidget {
  final double height;
  const _GradientHeroBackground({required this.height});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kPrimary, _kPrimaryDark],
            ),
          ),
        ),
        // Decorative glow — top right
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kSecondary.withValues(alpha: 0.08),
            ),
          ),
        ),
        // Decorative glow — bottom left
        Positioned(
          bottom: 0,
          left: -30,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPrimary.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}
