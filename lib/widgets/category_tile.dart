import 'package:flutter/material.dart';

import '../app/theme/app_typography.dart';
import '../data/models/category.dart';

/// A single category cell in the browse grid: the category's watercolor icon
/// fills the tile, with the title in a soft scrim along the bottom.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final tint = category.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Soft, natural hairline — lets the watercolor edge breathe instead
          // of a hard frame.
          border: Border.all(color: tint.withValues(alpha: 0.12)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Tinted ground (visible behind transparent icon edges / on load).
            ColoredBox(
              color: Color.alphaBlend(
                tint.withValues(alpha: 0.14),
                theme.colorScheme.surface,
              ),
            ),
            Image.asset(
              'assets/images/icons/${category.id}.webp',
              fit: BoxFit.cover,
              // No icon art yet -> keep the emoji centered on the tint ground.
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            // Bottom scrim so the title stays legible over any artwork.
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x99231A12), Color(0x00231A12)],
                  ),
                ),
                child: Text(
                  category.title.of(lang),
                  style: AppTypography.titleL.copyWith(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
