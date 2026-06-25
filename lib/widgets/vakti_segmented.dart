import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_typography.dart';

/// A single option in a [VaktiSegmented] control.
class VaktiSegment<T> {
  const VaktiSegment(this.value, this.label);
  final T value;
  final String label;
}

/// Rounded "pill" segmented control — saffron-filled selected segment on a
/// hairline-bordered track. Matches the golden-hour settings design.
class VaktiSegmented<T> extends StatelessWidget {
  const VaktiSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<VaktiSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          for (final seg in segments)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(seg.value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: seg.value == selected
                        ? AppColors.saffron
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      seg.label,
                      style: AppTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: seg.value == selected
                            ? AppColors.ink
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
