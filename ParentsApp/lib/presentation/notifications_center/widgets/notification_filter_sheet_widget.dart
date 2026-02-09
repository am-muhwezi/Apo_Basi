import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationFilterSheetWidget extends StatefulWidget {
  final List<String> selectedTypes;
  final Function(List<String>) onFiltersChanged;

  const NotificationFilterSheetWidget({
    Key? key,
    required this.selectedTypes,
    required this.onFiltersChanged,
  }) : super(key: key);

  @override
  State<NotificationFilterSheetWidget> createState() =>
      _NotificationFilterSheetWidgetState();
}

class _NotificationFilterSheetWidgetState
    extends State<NotificationFilterSheetWidget> {
  late List<String> _selectedTypes;

  final List<Map<String, dynamic>> _filterOptions = [
    {
      'type': 'bus_approaching',
      'label': 'Bus Approaching',
      'icon': 'directions_bus',
      'color': Color(0xFF2B5CE6),
      'bgColor': Color(0xFF2B5CE6),
    },
    {
      'type': 'pickup_confirmed',
      'label': 'Pickup Confirmed',
      'icon': 'check_circle',
      'color': Color(0xFF34C759),
      'bgColor': Color(0xFF0F4C25),
    },
    {
      'type': 'dropoff_complete',
      'label': 'Dropoff Complete',
      'icon': 'verified',
      'color': Color(0xFF22C55E),
      'bgColor': Color(0xFF0F4C25),
    },
    {
      'type': 'route_change',
      'label': 'Route Changes',
      'icon': 'alt_route',
      'color': Color(0xFFFF9500),
      'bgColor': Color(0xFF663D00),
    },
    {
      'type': 'emergency',
      'label': 'Emergency Alerts',
      'icon': 'warning',
      'color': Color(0xFFFF3B30),
      'bgColor': Color(0xFF5C0A05),
    },
    {
      'type': 'major_delay',
      'label': 'Major Delays',
      'icon': 'schedule',
      'color': Color(0xFFEF4444),
      'bgColor': Color(0xFF5C0A05),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTypes = List.from(widget.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTypes.clear();
                        });
                      },
                      child: Text(
                        'Clear All',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Notification Types',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(height: 2.h),
                ..._filterOptions.map((option) => _buildFilterOption(option)),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onFiltersChanged(_selectedTypes);
                          Navigator.pop(context);
                        },
                        child: Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(Map<String, dynamic> option) {
    final bool isSelected = _selectedTypes.contains(option['type']);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTypes.remove(option['type']);
              } else {
                _selectedTypes.add(option['type']);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? option['color']
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? option['color'].withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: option['color'].withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: option['color'].withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: option['icon'],
                    color: option['color'],
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    option['label'],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? option['color']
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                if (isSelected)
                  CustomIconWidget(
                    iconName: 'check',
                    color: option['color'],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
