import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeChanged;

  const DateRangeSelector({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      color: colorScheme.surface,
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'date_range',
            color: AppTheme.primaryDriver,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getDateRangeText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (startDate != null || endDate != null)
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: (startDate != null || endDate != null)
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (startDate != null || endDate != null) ...[
            SizedBox(width: 2.w),
            IconButton(
              onPressed: () => onDateRangeChanged(null, null),
              icon: CustomIconWidget(
                iconName: 'clear',
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              tooltip: 'Clear date range',
            ),
          ],
        ],
      ),
    );
  }

  String _getDateRangeText() {
    if (startDate == null && endDate == null) {
      return 'Select date range';
    } else if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
    } else if (startDate != null) {
      return 'From ${_formatDate(startDate!)}';
    } else if (endDate != null) {
      return 'Until ${_formatDate(endDate!)}';
    }
    return 'Select date range';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (startDate != null && endDate != null)
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
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
      onDateRangeChanged(picked.start, picked.end);
    }
  }
}

