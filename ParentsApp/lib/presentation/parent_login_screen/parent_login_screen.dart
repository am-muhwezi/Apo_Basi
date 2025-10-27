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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome! You have ${response['children'].length} child(ren)'),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: SvgPicture.asset(
                'assets/images/bg_pattern.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main content
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Welcome Header
                  WelcomeHeaderWidget(),

                  // Login Form
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),

                        // Phone Number Input
                        Text(
                          'Phone Number',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
