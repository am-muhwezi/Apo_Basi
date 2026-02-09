import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SchoolCodeInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? errorText;
  final bool isValid;

  const SchoolCodeInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.isValid = false,
  }) : super(key: key);

  @override
  State<SchoolCodeInputWidget> createState() => _SchoolCodeInputWidgetState();
}

class _SchoolCodeInputWidgetState extends State<SchoolCodeInputWidget> {
  bool _isFocused = false;

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
                  ? Theme.of(context).colorScheme.error
                  : _isFocused
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
              width: _isFocused ? 2 : 1,
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: TextFormField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            style: Theme.of(context).textTheme.bodyLarge,
            onTap: () {
              setState(() {
                _isFocused = true;
              });
            },
            onEditingComplete: () {
              setState(() {
                _isFocused = false;
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter school code',
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'school',
                  color: widget.errorText != null
                      ? Theme.of(context).colorScheme.error
                      : _isFocused
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
              ),
              suffixIcon: widget.isValid
                  ? Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'check_circle',
                        color: Theme.of(context).colorScheme.secondary,
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
                  color: Theme.of(context).colorScheme.error,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
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
