import 'package:flutter/material.dart';

class ChildInformationWidget extends StatelessWidget {
  final Map<String, dynamic> childData;
  final VoidCallback? onTap;

  const ChildInformationWidget({
    Key? key,
    required this.childData,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final String name = childData['name'] ?? 'Child Name';
    final String grade = childData['grade'] ?? '';
    final String? status = childData['status']?.toString().toLowerCase();
    final bool hasActiveStatus = status == 'on_bus' ||
        status == 'on-bus' ||
        status == 'picked_up' ||
        status == 'picked-up';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : const Color(0xFFE9E7F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + grade
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (grade.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      grade,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Active status dot
            if (hasActiveStatus)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
