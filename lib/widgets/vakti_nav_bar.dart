import 'package:flutter/material.dart';

import '../app/theme/app_typography.dart';

class VaktiNavItem {
  const VaktiNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Flat bottom navigation — line icons + labels, no pill. The active tab reads
/// in full-strength text/icon colour; the rest are muted. Hairline on top.
class VaktiNavBar extends StatelessWidget {
  const VaktiNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<VaktiNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = theme.colorScheme.onSurface;
    final muted = theme.textTheme.bodySmall?.color;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 24,
                          color: i == currentIndex ? active : muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: i == currentIndex ? active : muted,
                            fontWeight: i == currentIndex
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
