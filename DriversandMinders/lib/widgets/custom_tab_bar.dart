import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom tab bar implementing adaptive professional minimalism
/// for transportation management applications.
///
/// Provides role-based theming with clear visual hierarchy and
/// optimized for quick task resumption in mobile contexts.
class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// List of tab configurations
  final List<CustomTab> tabs;

  /// Current selected index
  final int currentIndex;

  /// Callback when tab is tapped
  final ValueChanged<int> onTap;

  /// Tab bar variant for different contexts
  final CustomTabBarVariant variant;

  /// Whether tabs are scrollable
  final bool isScrollable;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom selected color
  final Color? selectedColor;

  /// Custom unselected color
  final Color? unselectedColor;

  /// Custom indicator color
  final Color? indicatorColor;

  /// Tab alignment for scrollable tabs
  final TabAlignment? tabAlignment;

  /// Whether to show divider
  final bool showDivider;

  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.variant = CustomTabBarVariant.standard,
    this.isScrollable = false,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.tabAlignment,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine effective colors based on variant
    final effectiveBackgroundColor = backgroundColor ??
        (variant == CustomTabBarVariant.surface
            ? colorScheme.surface
            : colorScheme.primary);

    final effectiveSelectedColor = selectedColor ??
        (variant == CustomTabBarVariant.surface
            ? colorScheme.primary
            : colorScheme.onPrimary);

    final effectiveUnselectedColor = unselectedColor ??
        (variant == CustomTabBarVariant.surface
            ? colorScheme.onSurface.withValues(alpha: 0.6)
            : colorScheme.onPrimary.withValues(alpha: 0.7));

    final effectiveIndicatorColor = indicatorColor ?? effectiveSelectedColor;

    return Container(
      color: effectiveBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48.0,
            child: TabBar(
              tabs: tabs.map((tab) => _buildTab(context, tab)).toList(),
              controller: null, // Let parent handle controller
              isScrollable: isScrollable,
              tabAlignment: tabAlignment,
              labelColor: effectiveSelectedColor,
              unselectedLabelColor: effectiveUnselectedColor,
              indicatorColor: effectiveIndicatorColor,
              indicatorWeight: 3.0,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
              onTap: (index) {
                HapticFeedback.selectionClick();
                onTap(index);

                // Navigate to route if specified
                final tab = tabs[index];
                if (tab.route != null) {
                  Navigator.pushNamed(context, tab.route!);
                }
              },
              splashFactory: InkRipple.splashFactory,
              overlayColor: WidgetStateProperty.all(
                effectiveSelectedColor.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Divider
          if (showDivider)
            Container(
              height: 1.0,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
        ],
      ),
    );
  }

  /// Builds individual tab widget
  Widget _buildTab(BuildContext context, CustomTab tab) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tab.icon != null) ...[
              Icon(
                tab.icon,
                size: 18.0,
              ),
              if (tab.text.isNotEmpty) const SizedBox(width: 6.0),
            ],
            if (tab.text.isNotEmpty)
              Flexible(
                child: Text(
                  tab.text,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            if (tab.badge != null) ...[
              const SizedBox(width: 6.0),
              tab.badge!,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(48.0 + (showDivider ? 1.0 : 0.0));
}

/// Tab bar variants for different contexts
enum CustomTabBarVariant {
  /// Standard tab bar with primary background
  standard,

  /// Surface tab bar with surface background
  surface,

  /// Transparent tab bar for overlay contexts
  transparent,
}

/// Custom tab configuration
class CustomTab {
  /// Tab text
  final String text;

  /// Optional tab icon
  final IconData? icon;

  /// Optional badge widget
  final Widget? badge;

  /// Optional route to navigate to
  final String? route;

  /// Optional tooltip
  final String? tooltip;

  const CustomTab({
    required this.text,
    this.icon,
    this.badge,
    this.route,
    this.tooltip,
  });
}

/// Factory constructors for common tab bar configurations
extension CustomTabBarFactory on CustomTabBar {
  /// Creates a driver-focused tab bar
  static CustomTabBar driver({
    required List<CustomTab> tabs,
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool isScrollable = false,
  }) {
    return CustomTabBar(
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomTabBarVariant.standard,
      isScrollable: isScrollable,
      showDivider: true,
    );
  }

  /// Creates a busminder-focused tab bar
  static CustomTabBar busminder({
    required List<CustomTab> tabs,
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool isScrollable = false,
  }) {
    return CustomTabBar(
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomTabBarVariant.surface,
      isScrollable: isScrollable,
      showDivider: false,
    );
  }

  /// Creates a surface tab bar for secondary navigation
  static CustomTabBar surface({
    required List<CustomTab> tabs,
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool isScrollable = true,
  }) {
    return CustomTabBar(
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomTabBarVariant.surface,
      isScrollable: isScrollable,
      tabAlignment: TabAlignment.start,
    );
  }

  /// Creates trip status tabs for driver interface
  static CustomTabBar tripStatus({
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return CustomTabBar(
      tabs: const [
        CustomTab(
          text: 'Active',
          icon: Icons.directions_bus,
          route: '/driver-active-trip-screen',
        ),
        CustomTab(
          text: 'History',
          icon: Icons.history,
          route: '/driver-trip-history-screen',
        ),
      ],
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomTabBarVariant.standard,
    );
  }

  /// Creates attendance tabs for busminder interface
  static CustomTabBar attendance({
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return CustomTabBar(
      tabs: const [
        CustomTab(
          text: 'Check-in',
          icon: Icons.login,
        ),
        CustomTab(
          text: 'Check-out',
          icon: Icons.logout,
        ),
        CustomTab(
          text: 'Progress',
          icon: Icons.route,
          route: '/busminder-trip-progress-screen',
        ),
      ],
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomTabBarVariant.surface,
      isScrollable: true,
    );
  }
}

/// Badge widget for tab notifications
class TabBadge extends StatelessWidget {
  /// Badge count
  final int count;

  /// Badge color
  final Color? color;

  /// Text color
  final Color? textColor;

  const TabBadge({
    super.key,
    required this.count,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (count <= 0) return const SizedBox.shrink();

    final effectiveColor = color ?? colorScheme.error;
    final effectiveTextColor = textColor ?? colorScheme.onError;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      constraints: const BoxConstraints(
        minWidth: 16.0,
        minHeight: 16.0,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: effectiveTextColor,
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
