import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// iOS-standard sign-in button (48pt height minimum)
/// Features: Haptic feedback, smooth animations, loading state
class SignInButtonWidget extends StatefulWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;
  final String? buttonText;

  const SignInButtonWidget({
    Key? key,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    this.buttonText,
  }) : super(key: key);

  @override
  State<SignInButtonWidget> createState() => _SignInButtonWidgetState();
}

class _SignInButtonWidgetState extends State<SignInButtonWidget> {
  bool _isPressed = false;

  void _handleTap() {
    if (!widget.isEnabled || widget.isLoading) return;

    // Haptic feedback (iOS standard)
    HapticFeedback.lightImpact();

    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isPressed = false);
    });

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isEnabled && !widget.isLoading;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        height: 56, // iOS-standard button height (48pt minimum)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: _handleTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive
                ? AppTheme.primaryLight // ApoBasi blue
                : AppTheme.dividerLight,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.buttonText ?? 'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 17, // iOS standard button text
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
        ),
      ),
    );
  }
}
