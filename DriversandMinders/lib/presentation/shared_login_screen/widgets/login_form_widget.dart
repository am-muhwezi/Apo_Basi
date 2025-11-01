import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class LoginFormWidget extends StatefulWidget {
  final Function(String) onLogin;
  final bool isLoading;
  final String? errorMessage;

  const LoginFormWidget({
    super.key,
    required this.onLogin,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final TextEditingController _idController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();
  String? _validationError;

  @override
  void dispose() {
    _idController.dispose();
    _idFocusNode.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) return false;

    // Accept phone numbers with or without country code
    // Minimum 9 digits, maximum 15 digits
    final phonePattern = RegExp(r'^\+?[0-9]{9,15}$');
    return phonePattern.hasMatch(phone);
  }

  void _validateAndSubmit() {
    final phone = _idController.text.trim();

    setState(() {
      _validationError = null;
    });

    if (phone.isEmpty) {
      setState(() {
        _validationError = 'Please enter your phone number';
      });
      return;
    }

    if (!_isValidPhone(phone)) {
      setState(() {
        _validationError = 'Please enter a valid phone number';
      });
      return;
    }

    // Send to API
    widget.onLogin(phone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 85.w,
      padding: EdgeInsets.all(4.w),
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
          // Form Title
          Text(
            'Welcome Back',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 1.h),

          Text(
            'Enter your phone number to continue',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 3.h),

          // Phone Number Input Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              TextFormField(
                controller: _idController,
                focusNode: _idFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                enabled: !widget.isLoading,
                onChanged: (value) {
                  if (_validationError != null) {
                    setState(() {
                      _validationError = null;
                    });
                  }
                },
                onFieldSubmitted: (_) => _validateAndSubmit(),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g., 0773882123 or +256773882123',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'phone',
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                  errorText: _validationError,
                  errorMaxLines: 2,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
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

          SizedBox(height: 3.h),

          // Login Button
          SizedBox(
            height: 6.h,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 2,
                shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
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
                      'Login',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
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

          SizedBox(height: 2.h),

          // Help Text
          Text(
            'Need help? Contact your administrator',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
