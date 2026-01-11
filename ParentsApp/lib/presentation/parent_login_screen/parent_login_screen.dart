import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../models/child_model.dart';
import './widgets/phone_number_input_widget.dart';
import './widgets/sign_in_button_widget.dart';
import './widgets/welcome_header_widget.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _phoneError;
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    setState(() {
      if (phone.isEmpty) {
        _phoneError = null;
        _isPhoneValid = false;
      } else if (phone.length < 8) {
        _phoneError = 'Phone number must be at least 8 digits';
        _isPhoneValid = false;
      } else if (!RegExp(r'^[0-9+]+$').hasMatch(phone)) {
        _phoneError = 'Phone number can only contain digits and +';
        _isPhoneValid = false;
      } else {
        _phoneError = null;
        _isPhoneValid = true;
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_isPhoneValid) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _phoneError = null;
    });

    HapticFeedback.lightImpact();

    try {
      final phone = _phoneController.text.trim();

      // Call backend API for direct phone login
      final response = await _apiService.directPhoneLogin(phone);

      HapticFeedback.selectionClick();

      // Get parent name from response
      String parentName = 'Parent';
      if (response['user'] != null) {
        parentName = response['user']['first_name'] ??
            response['user']['username'] ??
            'Parent';
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, $parentName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to parent dashboard screen
      Navigator.pushReplacementNamed(
        context,
        '/parent-dashboard',
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _phoneError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Welcome Header (sleek gradient design)
              WelcomeHeaderWidget(),

              // Login Form
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Phone Number Input
                    Text(
                      'Phone Number',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    PhoneNumberInputWidget(
                      controller: _phoneController,
                      onChanged: (_) => _validatePhone(),
                      errorText: _phoneError,
                      isValid: _isPhoneValid,
                    ),

                    SizedBox(height: 3.h),

                    // Login Button
                    SignInButtonWidget(
                      isEnabled: _isPhoneValid,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                      buttonText: 'Sign In',
                    ),

                    SizedBox(height: 4.h),

                    // Footer
                    Center(
                      child: Text(
                        '© 2026 ApoBasi - Powered by SoG',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface
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
}
