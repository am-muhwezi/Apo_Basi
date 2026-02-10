import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StudentIdInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? errorText;
  final bool isValid;

  const StudentIdInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.isValid = false,
  }) : super(key: key);

  @override
  State<StudentIdInputWidget> createState() => _StudentIdInputWidgetState();
}

class _StudentIdInputWidgetState extends State<StudentIdInputWidget> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? AppTheme.lightTheme.colorScheme.error
                  : _isFocused
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
              width: _isFocused ? 2 : 1,
            ),
            color: AppTheme.lightTheme.colorScheme.surface,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            keyboardType: TextInputType.number,
            style: AppTheme.lightTheme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Enter student ID',
              hintStyle: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'person',
                  color: widget.errorText != null
                      ? AppTheme.lightTheme.colorScheme.error
                      : _isFocused
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
              ),
              suffixIcon: widget.isValid
                  ? Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'check_circle',
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        size: 6.w,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 3.h,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'error_outline',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
