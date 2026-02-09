import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// iOS-standard phone input with 48pt minimum height
/// Features: Focus states, validation feedback, smooth animations
class PhoneNumberInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? errorText;
  final bool isValid;

  const PhoneNumberInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.isValid = false,
  }) : super(key: key);

  @override
  State<PhoneNumberInputWidget> createState() => _PhoneNumberInputWidgetState();
}

class _PhoneNumberInputWidgetState extends State<PhoneNumberInputWidget> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // Determine border color based on state
    Color borderColor = AppTheme.dividerLight;
    if (widget.errorText != null) {
      borderColor = AppTheme.errorLight;
    } else if (_isFocused) {
      borderColor = AppTheme.primaryLight;
    } else if (widget.isValid) {
      borderColor = AppTheme.secondaryLight;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field with iOS-standard 48pt height
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 2 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              LengthLimitingTextInputFormatter(15),
            ],
            style: GoogleFonts.inter(
              fontSize: 17, // iOS standard
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
              color: AppTheme.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: '+256 700 000 000',
              hintStyle: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondaryLight,
              ),
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: _isFocused
                    ? AppTheme.primaryLight
                    : AppTheme.textSecondaryLight,
                size: 22,
              ),
              suffixIcon: widget.isValid
                  ? Icon(
                      Icons.check_circle,
                      color: AppTheme.secondaryLight,
                      size: 22,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14, // Ensures 48pt total height
              ),
            ),
            onTap: () => setState(() => _isFocused = true),
            onTapOutside: (_) => setState(() => _isFocused = false),
            onEditingComplete: () => setState(() => _isFocused = false),
          ),
        ),

        // Error message with animation
        if (widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 1.h, left: 2.w),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppTheme.errorLight,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.errorLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
