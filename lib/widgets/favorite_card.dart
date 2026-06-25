import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_typography.dart';
import '../data/models/category.dart';
import '../data/models/tip.dart';
import 'pill_badge.dart';
import 'tip_actions.dart';

/// Compact list row for the favorites tab: illustration thumbnail + title +
/// "when", with the save/share rail. Sized to its content (no fixed height),
/// so nothing overflows the way the full [TipCard] did when squeezed.
class FavoriteCard extends StatelessWidget {
  const FavoriteCard({super.key, required this.tip, required this.onTap});

  final Tip tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final category = categoryById(tip.category);
    final tint = category?.color ?? AppColors.saffron;
    final muted = theme.textTheme.bodySmall?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            tint.withValues(alpha: 0.06),
            theme.colorScheme.surface,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Image.asset(
                  'assets/images/cards/${tip.id}.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: tint.withValues(alpha: 0.12),
                    child: Center(
                      child: Text(
                        tip.emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null)
                    PillBadge(
                      label: category.title.of(lang),
                      color: tint,
                      emoji: tip.emoji,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    tip.title.of(lang),
                    style: AppTypography.titleL.copyWith(fontSize: 17),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${tip.primaryLabel.of(lang).toUpperCase()} · ${tip.primary.of(lang)}',
                    style: AppTypography.bodyM.copyWith(
                      fontSize: 13,
                      color: muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TipActions(tip: tip),
          ],
        ),
      ),
    );
  }
}
