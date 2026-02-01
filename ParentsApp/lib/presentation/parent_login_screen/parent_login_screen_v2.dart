import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';

/// ApoBasi Login Screen with Magic Link Authentication
///
/// Design based on brand guidelines:
/// - Light/white background
/// - Clean email input with subtle border
/// - Purple "Send login link" CTA button
/// - ApoBasi brand colors
class ParentLoginScreenV2 extends StatefulWidget {
  const ParentLoginScreenV2({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreenV2> createState() => _ParentLoginScreenV2State();
}

class _ParentLoginScreenV2State extends State<ParentLoginScreenV2>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _magicLinkSent = false;
  String? _emailError;
  bool _isEmailValid = false;
  StreamSubscription<AuthResult>? _authSubscription;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _listenForAuthCallback();

    // Fade-in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authSubscription?.cancel();
    _fadeController.dispose();
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
        HapticFeedback.mediumImpact();

        final firstName = result.parent?['firstName'] ?? 'there';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $firstName!'),
            backgroundColor: AppTheme.secondaryLight,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacementNamed(context, '/parent-dashboard');
      } else {
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Authentication failed'),
            backgroundColor: AppTheme.errorLight,
            behavior: SnackBarBehavior.floating,
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

        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Magic link sent!'),
            backgroundColor: AppTheme.secondaryLight,
            behavior: SnackBarBehavior.floating,
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
    // Set status bar for light background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: _magicLinkSent ? _buildMagicLinkSentView() : _buildEmailInputView(),
          ),
        ),
      ),
    );
  }

  /// Email Input View - Clean ApoBasi style
  Widget _buildEmailInputView() {
    return Stack(
      children: [
        // Main Content
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8.h),

              // Logo
              Center(
                child: Image.asset(
                  'assets/AB_logo2.png',
                  width: 45.w,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: 6.h),

              // Email Input Field
              _buildEmailInputField(),

              if (_emailError != null) ...[
                SizedBox(height: 1.h),
                Text(
                  _emailError!,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.errorLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              SizedBox(height: 3.h),

              // Send Login Link Button
              _buildContinueButton(),

              SizedBox(height: 4.h),

              // Footer info
              Center(
                child: Text(
                  'Please use email address registered with school',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.white.withOpacity(0.8),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryLight),
              ),
            ),
          ),
      ],
    );
  }

  /// Magic Link Sent View - Success State
  Widget _buildMagicLinkSentView() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),

          // Logo
          Center(
            child: Image.asset(
              'assets/AB_logo2.png',
              width: 35.w,
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(height: 6.h),

          // Success Icon
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.secondaryLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: 10.w,
              color: AppTheme.secondaryLight,
            ),
          ),

          SizedBox(height: 3.h),

          // Heading
          Text(
            'Check your email',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: 2.h),

          // Email address
          Text(
            _emailController.text.trim(),
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.apobasiPurple,
            ),
          ),

          SizedBox(height: 2.h),

          // Instructions
          Text(
            'We sent you a sign-in link.\nClick the link in your email to continue.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondaryLight,
              height: 1.5,
            ),
          ),

          SizedBox(height: 4.h),

          // Use different email button
          TextButton(
            onPressed: () {
              setState(() {
                _magicLinkSent = false;
                _emailController.clear();
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 6.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.apobasiPurple),
              ),
            ),
            child: Text(
              'Use a different email',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.apobasiPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Email Input Field - Clean ApoBasi style
  Widget _buildEmailInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _emailError != null
              ? AppTheme.errorLight
              : AppTheme.dividerLight,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          fontWeight: FontWeight.w400,
          color: AppTheme.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: 'you@email.com',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.textSecondaryLight,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 6.w,
            vertical: 2.h,
          ),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Icon(
              Icons.email_outlined,
              color: AppTheme.textSecondaryLight,
              size: 5.w,
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 10.w),
          suffixIcon: _isEmailValid
              ? Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryLight,
                    size: 5.w,
                  ),
                )
              : SizedBox(width: 10.w),
          suffixIconConstraints: BoxConstraints(minWidth: 10.w),
        ),
      ),
    );
  }

  /// Send Login Link Button - ApoBasi purple CTA
  Widget _buildContinueButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isEmailValid && !_isLoading ? _handleSendMagicLink : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.apobasiYellow,
          disabledBackgroundColor: AppTheme.apobasiYellow.withOpacity(0.5),
          foregroundColor: AppTheme.apobasiNavy,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              size: 18.sp,
            ),
            SizedBox(width: 2.w),
            Text(
              'Send login link',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
