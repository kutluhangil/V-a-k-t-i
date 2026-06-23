import 'package:flutter/material.dart';

import '../app/theme/app_typography.dart';
import '../data/models/category.dart';

/// A single category cell in the browse grid: emoji + title on a tinted ground.
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            tint.withValues(alpha: 0.14),
            theme.colorScheme.surface,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tint.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 30)),
            const Spacer(),
            Text(
              category.title.of(lang),
              style: AppTypography.titleL.copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
