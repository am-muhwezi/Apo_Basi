import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/demo_toggle_widget.dart';
import './widgets/phone_number_input_widget.dart';
import './widgets/otp_input_widget.dart';
import './widgets/sign_in_button_widget.dart';
import './widgets/welcome_header_widget.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isDemoMode = false;
  bool _otpSent = false;
  String? _phoneError;
  String? _otpError;
  bool _isPhoneValid = false;
  int _resendCountdown = 0;

  // Ugandan phone number prefixes (MTN, Airtel, Africell, Uganda Telecom)
  final List<String> validPhonePrefixes = [
    '075', '074', '077', '078', // MTN Uganda
    '070', '071', '072', // Airtel Uganda
    '079',                // Uganda Telecom
    '073'                 // Africell Uganda
  ];

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
      } else if (phone.length != 10) {
        _phoneError = 'Phone number must be 10 digits';
        _isPhoneValid = false;
      } else if (!phone.startsWith('0')) {
        _phoneError = 'Phone number must start with 0';
        _isPhoneValid = false;
      } else if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        _phoneError = 'Phone number can only contain digits';
        _isPhoneValid = false;
      } else if (!validPhonePrefixes.any((prefix) => phone.startsWith(prefix))) {
        _phoneError = 'Invalid Ugandan phone number';
        _isPhoneValid = false;
      } else {
        _phoneError = null;
        _isPhoneValid = true;
      }
    });
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        return true;
      }
      return false;
    });
  }

  bool get _canSendOtp => _isPhoneValid && !_otpSent;

  void _toggleDemoMode(bool enabled) {
    setState(() {
      _isDemoMode = enabled;
      if (enabled) {
        _phoneController.text = '0776102830'; // Default demo number
      } else {
        _phoneController.clear();
        _otpSent = false;
        _otpError = null;
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_canSendOtp) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _phoneError = null;
    });

    HapticFeedback.lightImpact();

    try {
      // Simulate OTP sending delay
      await Future.delayed(const Duration(seconds: 2));

      // In production, call your backend API to send OTP
      // For demo, accept any valid Nigerian phone number
      final phone = _phoneController.text.trim();

      if (validPhonePrefixes.any((prefix) => phone.startsWith(prefix))) {
        HapticFeedback.selectionClick();

        setState(() {
          _otpSent = true;
        });

        _startResendCountdown();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${_phoneController.text}'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _phoneError = 'Invalid phone number';
        });
      }
    } catch (e) {
      setState(() {
        _phoneError = 'Failed to send OTP. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyOtp(String otp) async {
    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    HapticFeedback.lightImpact();

    try {
      // Simulate OTP verification delay
      await Future.delayed(const Duration(seconds: 2));

      // For demo, accept OTP "123456" or any 6-digit code
      if (otp.length == 6) {
        HapticFeedback.selectionClick();

        // Navigate to parent dashboard
        Navigator.pushReplacementNamed(context, '/parent-dashboard');
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _otpError = 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _otpError = 'Verification failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _otpSent = false;
      _otpError = null;
    });

    await _handleSendOtp();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
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

                        SizedBox(height: 2.h),

                        // OTP Section (shown after phone is valid)
                        if (_otpSent) ...[
                          Text(
                            'Enter OTP',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'We sent a 6-digit code to ${_phoneController.text}',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          OtpInputWidget(
                            onCompleted: _handleVerifyOtp,
                            errorText: _otpError,
                          ),
                          SizedBox(height: 3.h),
                          // Resend OTP
                          Center(
                            child: TextButton(
                              onPressed:
                                  _resendCountdown > 0 ? null : _handleResendOtp,
                              child: Text(
                                _resendCountdown > 0
                                    ? 'Resend OTP in ${_resendCountdown}s'
                                    : 'Resend OTP',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: _resendCountdown > 0
                                      ? AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant
                                      : AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(height: 2.h),
                          // Send OTP Button
                          SignInButtonWidget(
                            isEnabled: _canSendOtp,
                            isLoading: _isLoading,
                            onPressed: _handleSendOtp,
                            buttonText: 'Send OTP',
                          ),
                        ],

                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Demo Toggle
          DemoToggleWidget(
            isDemoMode: _isDemoMode,
            onToggle: _toggleDemoMode,
          ),
        ],
      ),
    );
  }
}
