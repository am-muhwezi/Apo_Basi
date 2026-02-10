import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

enum LoginMethod { email, phone }

class LoginMethodToggle extends StatelessWidget {
  final LoginMethod selectedMethod;
  final Function(LoginMethod) onMethodChanged;

  const LoginMethodToggle({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 85.w,
      padding: EdgeInsets.all(0.5.h),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceVariant.withValues(alpha: 0.3)
            : colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Email Button
          Expanded(
            child: _buildToggleButton(
              context: context,
              label: 'Email',
              icon: Icons.email_outlined,
              isSelected: selectedMethod == LoginMethod.email,
              onTap: () => onMethodChanged(LoginMethod.email),
            ),
          ),
          SizedBox(width: 1.w),
          // Phone Button
          Expanded(
            child: _buildToggleButton(
              context: context,
              label: 'Phone',
              icon: Icons.phone_outlined,
              isSelected: selectedMethod == LoginMethod.phone,
              onTap: () => onMethodChanged(LoginMethod.phone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: isSelected
            ? colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        elevation: isSelected ? 2 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 1.2.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                SizedBox(width: 1.5.w),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
