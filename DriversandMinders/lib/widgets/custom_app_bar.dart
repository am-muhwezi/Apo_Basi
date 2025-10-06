import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar widget implementing adaptive professional minimalism
/// for transportation management applications.
///
/// Provides role-based theming and high-contrast design optimized for
/// mobile-first contexts with clear visual hierarchy.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title to display in the app bar
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Leading widget (typically back button or menu)
  final Widget? leading;

  /// Actions to display on the right side
  final List<Widget>? actions;

  /// Whether to show the back button automatically
  final bool automaticallyImplyLeading;

  /// Background color override
  final Color? backgroundColor;

  /// Foreground color override
  final Color? foregroundColor;

  /// Elevation override
  final double? elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// App bar variant for different contexts
  final CustomAppBarVariant variant;

  /// Whether to show a bottom border
  final bool showBottomBorder;

  /// Custom bottom widget
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.variant = CustomAppBarVariant.standard,
    this.showBottomBorder = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on variant and theme
    final effectiveBackgroundColor = backgroundColor ??
        (variant == CustomAppBarVariant.transparent
            ? Colors.transparent
            : colorScheme.primary);

    final effectiveForegroundColor = foregroundColor ??
        (variant == CustomAppBarVariant.transparent
            ? colorScheme.onSurface
            : colorScheme.onPrimary);

    final effectiveElevation =
        elevation ?? (variant == CustomAppBarVariant.transparent ? 0.0 : 4.0);

    // Build title widget with optional subtitle
    Widget titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: effectiveForegroundColor,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: effectiveForegroundColor.withValues(alpha: 0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return AppBar(
      title: titleWidget,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: effectiveElevation,
      centerTitle: centerTitle,
      bottom: bottom ?? (showBottomBorder ? _buildBottomBorder(context) : null),
      systemOverlayStyle: _getSystemOverlayStyle(
        effectiveBackgroundColor,
        theme.brightness,
      ),
      titleSpacing: 16.0,
      toolbarHeight: subtitle != null ? 72.0 : 56.0,
      shape: showBottomBorder
          ? Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1.0,
              ),
            )
          : null,
    );
  }

  /// Builds a subtle bottom border
  PreferredSizeWidget _buildBottomBorder(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        height: 1.0,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      ),
    );
  }

  /// Determines system overlay style based on app bar colors
  SystemUiOverlayStyle _getSystemOverlayStyle(
    Color backgroundColor,
    Brightness brightness,
  ) {
    final isLight = backgroundColor.computeLuminance() > 0.5;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: backgroundColor,
      systemNavigationBarIconBrightness:
          isLight ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight((subtitle != null ? 72.0 : 56.0) +
      (bottom?.preferredSize.height ?? 0.0) +
      (showBottomBorder ? 1.0 : 0.0));
}

/// App bar variants for different contexts
enum CustomAppBarVariant {
  /// Standard app bar with primary color background
  standard,

  /// Transparent app bar for overlay contexts
  transparent,

  /// Surface app bar with surface color background
  surface,
}

/// Factory constructors for common app bar configurations
extension CustomAppBarFactory on CustomAppBar {
  /// Creates a driver-focused app bar with high contrast
  static CustomAppBar driver({
    required String title,
    String? subtitle,
    Widget? leading,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      variant: CustomAppBarVariant.standard,
      centerTitle: false,
      showBottomBorder: true,
    );
  }

  /// Creates a busminder-focused app bar with approachable styling
  static CustomAppBar busminder({
    required String title,
    String? subtitle,
    Widget? leading,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      variant: CustomAppBarVariant.standard,
      centerTitle: true,
    );
  }

  /// Creates a transparent overlay app bar
  static CustomAppBar overlay({
    required String title,
    String? subtitle,
    Widget? leading,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
  }) {
    return CustomAppBar(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      variant: CustomAppBarVariant.transparent,
      centerTitle: true,
    );
  }
}
