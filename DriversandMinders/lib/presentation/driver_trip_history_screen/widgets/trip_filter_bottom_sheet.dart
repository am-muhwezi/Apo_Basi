import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TripFilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const TripFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  @override
  State<TripFilterBottomSheet> createState() => _TripFilterBottomSheetState();
}

class _TripFilterBottomSheetState extends State<TripFilterBottomSheet> {
  late Map<String, dynamic> _filters;

  final List<String> _statusOptions = [
    'All',
    'Completed',
    'Cancelled',
    'Delayed'
  ];
  final List<String> _routeOptions = [
    'All Routes',
    'Route A',
    'Route B',
    'Route C',
    'Route D'
  ];
  final List<String> _timePeriodOptions = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'Last 30 Days'
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),

          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Trips',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Reset',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryDriver,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Status Filter
                  _buildFilterSection(
                    context,
                    'Trip Status',
                    _statusOptions,
                    _filters['status'] as String? ?? 'All',
                    (value) => setState(() => _filters['status'] = value),
                  ),

                  SizedBox(height: 2.h),

                  // Route Filter
                  _buildFilterSection(
                    context,
                    'Route',
                    _routeOptions,
                    _filters['route'] as String? ?? 'All Routes',
                    (value) => setState(() => _filters['route'] = value),
                  ),

                  SizedBox(height: 2.h),

                  // Time Period Filter
                  _buildFilterSection(
                    context,
                    'Time Period',
                    _timePeriodOptions,
                    _filters['timePeriod'] as String? ?? 'All Time',
                    (value) => setState(() => _filters['timePeriod'] = value),
                  ),

                  SizedBox(height: 2.h),

                  // Date Range Filter
                  _buildDateRangeSection(context),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      side: BorderSide(color: AppTheme.primaryDriver),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryDriver,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDriver,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return FilterChip(
              label: Text(
                option,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? AppTheme.textOnPrimary
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              backgroundColor: colorScheme.surface,
              selectedColor: AppTheme.primaryDriver,
              checkmarkColor: AppTheme.textOnPrimary,
              side: BorderSide(
                color:
                    isSelected ? AppTheme.primaryDriver : colorScheme.outline,
                width: 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final DateTime? startDate = _filters['startDate'] as DateTime?;
    final DateTime? endDate = _filters['endDate'] as DateTime?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Date Range',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context, true),
                icon: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.primaryDriver,
                  size: 16,
                ),
                label: Text(
                  startDate != null
                      ? '${startDate.day}/${startDate.month}/${startDate.year}'
                      : 'Start Date',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: startDate != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
                  side: BorderSide(color: AppTheme.primaryDriver),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectDate(context, false),
                icon: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.primaryDriver,
                  size: 16,
                ),
                label: Text(
                  endDate != null
                      ? '${endDate.day}/${endDate.month}/${endDate.year}'
                      : 'End Date',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: endDate != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(vertical: 1.2.h, horizontal: 3.w),
                  side: BorderSide(color: AppTheme.primaryDriver),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryDriver,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _filters['startDate'] = picked;
        } else {
          _filters['endDate'] = picked;
        }
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'status': 'All',
        'route': 'All Routes',
        'timePeriod': 'All Time',
        'startDate': null,
        'endDate': null,
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(_filters);
    Navigator.pop(context);
  }
}

