import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class LoginFormWidget extends StatefulWidget {
  final Function(String) onLogin;
  final bool isLoading;
  final bool magicLinkSent;
  final String? errorMessage;

  const LoginFormWidget({
    super.key,
    required this.onLogin,
    required this.isLoading,
    required this.magicLinkSent,
    this.errorMessage,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  String? _validationError;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _validationError = null;
        _isEmailValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _validationError = 'Please enter a valid email address';
        _isEmailValid = false;
      } else {
        _validationError = null;
        _isEmailValid = true;
      }
    });
  }

  void _validateAndSubmit() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _validationError = 'Please enter your email address';
      });
      return;
    }

    if (!_isEmailValid) {
      return;
    }

    FocusScope.of(context).unfocus();
    widget.onLogin(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 85.w,
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Magic Link Sent State or Login Form
          if (widget.magicLinkSent) ...[
            // Magic Link Sent State
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  Text(
                    'We sent a magic link to\n${_emailController.text}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Click the link in the email to sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            TextButton(
              onPressed: widget.isLoading ? null : () => widget.onLogin(_emailController.text.trim()),
              child: Text('Resend magic link'),
            ),
          ] else ...[
            // Login Form
            Text(
              'Welcome Back',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 0.5.h),

            Text(
              'For Drivers & Bus Assistants',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Email Input Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Address',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.8.h),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !widget.isLoading,
                  onFieldSubmitted: (_) => _validateAndSubmit(),
                  decoration: InputDecoration(
                    hintText: 'e.g., driver@example.com',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: CustomIconWidget(
                        iconName: 'email',
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 16,
                      ),
                    ),
                    errorText: _validationError,
                    errorMaxLines: 2,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.error,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Send Login Link Button
            SizedBox(
              height: 5.5.h,
              child: ElevatedButton(
                onPressed: (widget.isLoading || !_isEmailValid) ? null : _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 2,
                  shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.2.h),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Send Login Link',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
              ),
            ),

            // Error Message Display
            if (widget.errorMessage != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'error_outline',
                      color: colorScheme.error,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 1.5.h),

            // Help Text
            Text(
              'Need help? Contact your administrator',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
