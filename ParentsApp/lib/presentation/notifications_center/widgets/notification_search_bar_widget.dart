import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationSearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterTap;
  final bool isVisible;

  const NotificationSearchBarWidget({
    Key? key,
    required this.onSearchChanged,
    this.onFilterTap,
    this.isVisible = false,
  }) : super(key: key);

  @override
  State<NotificationSearchBarWidget> createState() =>
      _NotificationSearchBarWidgetState();
}

class _NotificationSearchBarWidgetState
    extends State<NotificationSearchBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NotificationSearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchController.clear();
        widget.onSearchChanged('');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _slideAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline
                    .withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow
                      .withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'search',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search notifications...',
                      hintStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_searchController.text.isNotEmpty) ...[
                  SizedBox(width: 2.w),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      widget.onSearchChanged('');
                    },
                    child: CustomIconWidget(
                      iconName: 'clear',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                ],
                SizedBox(width: 2.w),
                GestureDetector(
                  onTap: widget.onFilterTap,
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomIconWidget(
                      iconName: 'filter_list',
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
