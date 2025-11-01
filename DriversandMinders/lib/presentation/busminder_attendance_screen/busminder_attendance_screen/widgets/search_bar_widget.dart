import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Search bar widget for quick student lookup with real-time filtering
class SearchBarWidget extends StatefulWidget {
  final Function(String query) onSearchChanged;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.hintText = 'Search students by name...',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _isSearchActive = query.isNotEmpty;
    });
    widget.onSearchChanged(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
    });
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.lightBusminderTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: _isSearchActive
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBusminder.withValues(alpha: 0.05),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: _isSearchActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: _isSearchActive
                ? AppTheme.primaryBusminder.withValues(alpha: 0.3)
                : AppTheme.borderLight.withValues(alpha: 0.3),
            width: _isSearchActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isSearchActive
                  ? AppTheme.primaryBusminder.withValues(alpha: 0.1)
                  : AppTheme.shadowLight.withValues(alpha: 0.5),
              offset: Offset(0, _isSearchActive ? 4 : 2),
              blurRadius: _isSearchActive ? 12 : 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  gradient: _isSearchActive
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryBusminder,
                            AppTheme.primaryBusminderLight,
                          ],
                        )
                      : null,
                  color: _isSearchActive ? null : AppTheme.backgroundSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: _isSearchActive ? Colors.white : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
            ),
            suffixIcon: _isSearchActive
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Container(
                        padding: EdgeInsets.all(1.5.w),
                        decoration: BoxDecoration(
                          color: AppTheme.criticalAlert.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'close',
                          color: AppTheme.criticalAlert,
                          size: 18,
                        ),
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide.none,
            ),
            filled: false,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.5.h,
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            widget.onSearchChanged(value.trim());
          },
        ),
      ),
    );
  }
}
