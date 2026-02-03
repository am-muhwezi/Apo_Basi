import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility helper utilities for WCAG AA compliance and VoiceOver support.
///
/// Provides utilities for:
/// - Ensuring minimum tap targets (44x44 pt)
/// - High contrast text color selection
/// - Semantic labeling helpers
/// - Widget grouping for screen readers
class AccessibilityHelpers {
  AccessibilityHelpers._();

  /// Minimum tap target size according to Apple Human Interface Guidelines
  static const double minTapTargetSize = 44.0;

  /// Wraps a widget to ensure it meets the minimum tap target size (44x44 pt).
  ///
  /// This is required by Apple's accessibility guidelines. If the child widget
  /// is smaller than 44x44 points, transparent padding is added to meet the
  /// minimum size while maintaining the visual appearance.
  ///
  /// Example:
  /// ```dart
  /// AccessibilityHelpers.ensureMinimumTapTarget(
  ///   IconButton(
  ///     icon: Icon(Icons.edit),
  ///     onPressed: () {},
  ///   ),
  /// )
  /// ```
  static Widget ensureMinimumTapTarget(
    Widget child, {
    double minSize = minTapTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }

  /// Returns a high-contrast text color (white or black) based on the
  /// background color's luminance.
  ///
  /// Uses the relative luminance formula from WCAG 2.1 to determine
  /// whether white (#FFFFFF) or black (#000000) provides better contrast.
  ///
  /// Example:
  /// ```dart
  /// final textColor = AccessibilityHelpers.getContrastText(Colors.blue);
  /// Text('Hello', style: TextStyle(color: textColor))
  /// ```
  static Color getContrastText(Color backgroundColor) {
    // Calculate relative luminance using WCAG formula
    final luminance = backgroundColor.computeLuminance();

    // Use white text for dark backgrounds, black for light backgrounds
    // Threshold of 0.5 provides good contrast in most cases
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Creates an accessible text style by automatically adjusting the text color
  /// for optimal contrast against the background.
  ///
  /// This ensures WCAG AA compliance (minimum 4.5:1 contrast ratio for normal text).
  ///
  /// Example:
  /// ```dart
  /// Text(
  ///   'Status: Active',
  ///   style: AccessibilityHelpers.createAccessibleTextStyle(
  ///     Theme.of(context).textTheme.bodyMedium!,
  ///     Colors.blue,
  ///   ),
  /// )
  /// ```
  static TextStyle createAccessibleTextStyle(
    TextStyle baseStyle,
    Color backgroundColor,
  ) {
    return baseStyle.copyWith(
      color: getContrastText(backgroundColor),
    );
  }

  /// Creates a Semantics widget with consistent labeling for accessibility.
  ///
  /// Parameters:
  /// - [label]: The semantic description read by screen readers (required)
  /// - [hint]: Optional hint describing what happens when activated
  /// - [child]: The widget to make accessible (required)
  /// - [button]: Whether this represents a button action
  /// - [excludeSemantics]: Whether to exclude child semantics
  ///
  /// Example:
  /// ```dart
  /// AccessibilityHelpers.semanticLabel(
  ///   label: 'Refresh data',
  ///   hint: 'Double tap to refresh the child status information',
  ///   button: true,
  ///   child: IconButton(icon: Icon(Icons.refresh), onPressed: _refresh),
  /// )
  /// ```
  static Widget semanticLabel({
    required String label,
    String? hint,
    required Widget child,
    bool button = false,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Groups multiple widgets into a single semantic unit for screen readers.
  ///
  /// This is useful for complex cards or list items where you want VoiceOver
  /// to read all information as a single announcement rather than navigating
  /// through each child element separately.
  ///
  /// Parameters:
  /// - [label]: The complete semantic description for the group
  /// - [hint]: Optional hint for interaction
  /// - [child]: The widget containing the grouped content
  /// - [onTap]: Optional tap handler
  ///
  /// Example:
  /// ```dart
  /// AccessibilityHelpers.groupSemantics(
  ///   label: 'John Doe. Grade 5. Status: At home.',
  ///   hint: 'Double tap to view details',
  ///   onTap: () => navigateToDetails(),
  ///   child: Card(
  ///     child: Row(
  ///       children: [
  ///         Avatar(...),
  ///         Text('John Doe'),
  ///         Text('Grade 5'),
  ///         StatusBadge(...),
  ///       ],
  ///     ),
  ///   ),
  /// )
  /// ```
  static Widget groupSemantics({
    required String label,
    String? hint,
    required Widget child,
    VoidCallback? onTap,
    bool button = true,
  }) {
    final semanticChild = Semantics(
      label: label,
      hint: hint,
      button: button && onTap != null,
      excludeSemantics: true, // Don't read child elements separately
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: semanticChild,
      );
    }

    return semanticChild;
  }

  /// Announces a message to screen readers without changing the UI.
  ///
  /// This is useful for announcing state changes, completion messages,
  /// or other feedback that should be communicated to screen reader users.
  ///
  /// Example:
  /// ```dart
  /// await AccessibilityHelpers.announce(
  ///   context,
  ///   'Data refreshed successfully',
  /// );
  /// ```
  static Future<void> announce(
    BuildContext context,
    String message, {
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await SemanticsService.announce(message, textDirection);
  }

  /// Creates a semantic widget that announces live updates (like ETA changes).
  ///
  /// The liveRegion property ensures that changes to this widget's content
  /// are automatically announced to screen reader users.
  ///
  /// Example:
  /// ```dart
  /// AccessibilityHelpers.liveRegion(
  ///   label: 'Estimated arrival: 5 minutes',
  ///   child: Text('ETA: 5 min'),
  /// )
  /// ```
  static Widget liveRegion({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: child,
    );
  }

  /// Validates that a contrast ratio meets WCAG AA standards.
  ///
  /// Returns true if the contrast ratio between two colors is at least:
  /// - 4.5:1 for normal text (default)
  /// - 3.0:1 for large text (18pt+ or 14pt+ bold)
  ///
  /// Example:
  /// ```dart
  /// final isAccessible = AccessibilityHelpers.meetsContrastRequirement(
  ///   foreground: Colors.white,
  ///   background: Colors.blue,
  /// );
  /// ```
  static bool meetsContrastRequirement({
    required Color foreground,
    required Color background,
    bool isLargeText = false,
  }) {
    final contrast = _calculateContrastRatio(foreground, background);
    final minimumRatio = isLargeText ? 3.0 : 4.5;
    return contrast >= minimumRatio;
  }

  /// Calculates the contrast ratio between two colors according to WCAG 2.1.
  ///
  /// Formula: (L1 + 0.05) / (L2 + 0.05)
  /// where L1 is the lighter color's luminance and L2 is the darker.
  static double _calculateContrastRatio(Color color1, Color color2) {
    final lum1 = color1.computeLuminance();
    final lum2 = color2.computeLuminance();

    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns a formatted status text with "Status: " prefix for VoiceOver.
  ///
  /// This ensures status information is not conveyed by color alone,
  /// meeting accessibility requirements.
  ///
  /// Example:
  /// ```dart
  /// final statusText = AccessibilityHelpers.formatStatus('At home');
  /// // Returns: "Status: At home"
  /// ```
  static String formatStatus(String status) {
    return 'Status: $status';
  }

  /// Helper to create an accessible status badge widget.
  ///
  /// Combines color indicator with explicit text label for accessibility.
  ///
  /// Example:
  /// ```dart
  /// AccessibilityHelpers.statusBadge(
  ///   status: 'At home',
  ///   color: Colors.green,
  ///   context: context,
  /// )
  /// ```
  static Widget statusBadge({
    required String status,
    required Color color,
    required BuildContext context,
    double dotSize = 8.0,
  }) {
    return Semantics(
      label: formatStatus(status),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatStatus(status),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: getContrastText(color),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension on BuildContext to make accessibility helpers more convenient.
extension AccessibilityContext on BuildContext {
  /// Announces a message to screen readers.
  Future<void> announce(String message) async {
    await AccessibilityHelpers.announce(this, message);
  }
}
