import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_export.dart';

class PreTripChecklistWidget extends StatefulWidget {
  final List<Map<String, dynamic>> checklistItems;
  final Function(bool) onChecklistComplete;

  const PreTripChecklistWidget({
    super.key,
    required this.checklistItems,
    required this.onChecklistComplete,
  });

  @override
  State<PreTripChecklistWidget> createState() => _PreTripChecklistWidgetState();
}

class _PreTripChecklistWidgetState extends State<PreTripChecklistWidget> {
  bool _isExpanded = false;
  List<bool> _checkedItems = [];

  @override
  void initState() {
    super.initState();
    _loadChecklistState();
  }

  Future<void> _loadChecklistState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _checkedItems = List.generate(
        widget.checklistItems.length,
        (index) => prefs.getBool('checklist_$index') ?? false,
      );
    });
    _updateChecklistStatus();
  }

  Future<void> _saveChecklistState() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _checkedItems.length; i++) {
      await prefs.setBool('checklist_$i', _checkedItems[i]);
    }
  }

  void _updateChecklistStatus() {
    final allChecked = _checkedItems.every((checked) => checked);
    widget.onChecklistComplete(allChecked);
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _checkedItems.where((checked) => checked).length;
    final totalCount = widget.checklistItems.length;
    final isComplete = completedCount == totalCount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightDriverTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppTheme.successAction.withValues(alpha: 0.3)
              : AppTheme.warningState.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppTheme.successAction.withValues(alpha: 0.1)
                          : AppTheme.warningState.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: isComplete ? 'check_circle' : 'checklist',
                      color: isComplete
                          ? AppTheme.successAction
                          : AppTheme.warningState,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pre-Trip Safety Checklist',
                          style: AppTheme.lightDriverTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '$completedCount of $totalCount items completed',
                          style: AppTheme.lightDriverTheme.textTheme.bodySmall
                              ?.copyWith(
                            color: isComplete
                                ? AppTheme.successAction
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: AppTheme.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                children: widget.checklistItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isChecked = _checkedItems[index];

                  return Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _checkedItems[index] = !_checkedItems[index];
                        });
                        _saveChecklistState();
                        _updateChecklistStatus();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? AppTheme.successAction.withValues(alpha: 0.1)
                              : AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isChecked
                                ? AppTheme.successAction.withValues(alpha: 0.3)
                                : AppTheme.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppTheme.successAction
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isChecked
                                      ? AppTheme.successAction
                                      : AppTheme.textSecondary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: isChecked
                                  ? CustomIconWidget(
                                      iconName: 'check',
                                      color: AppTheme.textOnPrimary,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: AppTheme
                                        .lightDriverTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (item['description'] != null) ...[
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      item['description'] as String,
                                      style: AppTheme
                                          .lightDriverTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
