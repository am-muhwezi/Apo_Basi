import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double borderRadius;
  final ButtonVariant variant;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.width,
    this.borderRadius = 12,
    this.variant = ButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          );

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 2,
          ),
          child: child,
        );
        break;

      case ButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? Theme.of(context).colorScheme.primary,
            side: BorderSide(
              color: backgroundColor ?? Theme.of(context).colorScheme.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: child,
        );
        break;

      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: child,
        );
        break;

      case ButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.error,
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 2,
          ),
          child: child,
        );
        break;
    }

    return SizedBox(
      width: width,
      child: button,
    );
  }
}

enum ButtonVariant {
  primary,
  secondary,
  text,
  danger,
}