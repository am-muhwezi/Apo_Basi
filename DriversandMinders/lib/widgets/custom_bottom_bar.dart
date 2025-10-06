import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar implementing adaptive professional minimalism
/// for transportation management applications.
///
/// Provides role-based navigation with clear visual hierarchy and
/// optimized touch targets for mobile-first contexts.
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when item is tapped
  final ValueChanged<int> onTap;

  /// Bottom bar variant for different user roles
  final CustomBottomBarVariant variant;

  /// Whether to show labels
  final bool showLabels;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom selected item color
  final Color? selectedItemColor;

  /// Custom unselected item color
  final Color? unselectedItemColor;

  /// Elevation override
  final double? elevation;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.variant = CustomBottomBarVariant.driver,
    this.showLabels = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get navigation items based on variant
    final items = _getNavigationItems(variant);

    // Determine effective colors
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
    final effectiveSelectedColor = selectedItemColor ?? colorScheme.primary;
    final effectiveUnselectedColor =
        unselectedItemColor ?? colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: showLabels ? 72.0 : 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;

              return Expanded(
                child: _buildNavigationItem(
                  context,
                  item,
                  index,
                  isSelected,
                  effectiveSelectedColor,
                  effectiveUnselectedColor,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Builds individual navigation item
  Widget _buildNavigationItem(
    BuildContext context,
    _NavigationItem item,
    int index,
    bool isSelected,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final theme = Theme.of(context);
    final color = isSelected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);

        // Navigate to the corresponding route
        if (item.route != null) {
          Navigator.pushNamed(context, item.route!);
        }
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with selection indicator
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: isSelected
                  ? BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    )
                  : null,
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: color,
                size: 24.0,
              ),
            ),

            // Label
            if (showLabels) ...[
              const SizedBox(height: 4.0),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gets navigation items based on variant
  List<_NavigationItem> _getNavigationItems(CustomBottomBarVariant variant) {
    switch (variant) {
      case CustomBottomBarVariant.driver:
        return [
          _NavigationItem(
            icon: Icons.play_circle_outline,
            selectedIcon: Icons.play_circle,
            label: 'Start Shift',
            route: '/driver-start-shift-screen',
          ),
          _NavigationItem(
            icon: Icons.directions_bus_outlined,
            selectedIcon: Icons.directions_bus,
            label: 'Active Trip',
            route: '/driver-active-trip-screen',
          ),
          _NavigationItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            label: 'History',
            route: '/driver-trip-history-screen',
          ),
        ];

      case CustomBottomBarVariant.busminder:
        return [
          _NavigationItem(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: 'Attendance',
            route: '/busminder-attendance-screen',
          ),
          _NavigationItem(
            icon: Icons.route_outlined,
            selectedIcon: Icons.route,
            label: 'Trip Progress',
            route: '/busminder-trip-progress-screen',
          ),
        ];

      case CustomBottomBarVariant.shared:
        return [
          _NavigationItem(
            icon: Icons.login_outlined,
            selectedIcon: Icons.login,
            label: 'Login',
            route: '/shared-login-screen',
          ),
          _NavigationItem(
            icon: Icons.play_circle_outline,
            selectedIcon: Icons.play_circle,
            label: 'Start Shift',
            route: '/driver-start-shift-screen',
          ),
          _NavigationItem(
            icon: Icons.checklist_outlined,
            selectedIcon: Icons.checklist,
            label: 'Attendance',
            route: '/busminder-attendance-screen',
          ),
        ];
    }
  }
}

/// Bottom bar variants for different user roles
enum CustomBottomBarVariant {
  /// Driver-focused navigation
  driver,

  /// Busminder-focused navigation
  busminder,

  /// Shared navigation for multi-role contexts
  shared,
}

/// Internal navigation item model
class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? route;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.route,
  });
}

/// Factory constructors for common bottom bar configurations
extension CustomBottomBarFactory on CustomBottomBar {
  /// Creates a driver-focused bottom bar
  static CustomBottomBar driver({
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool showLabels = true,
  }) {
    return CustomBottomBar(
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomBottomBarVariant.driver,
      showLabels: showLabels,
    );
  }

  /// Creates a busminder-focused bottom bar
  static CustomBottomBar busminder({
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool showLabels = true,
  }) {
    return CustomBottomBar(
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomBottomBarVariant.busminder,
      showLabels: showLabels,
    );
  }

  /// Creates a shared bottom bar for multi-role contexts
  static CustomBottomBar shared({
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool showLabels = true,
  }) {
    return CustomBottomBar(
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomBottomBarVariant.shared,
      showLabels: showLabels,
    );
  }
}
