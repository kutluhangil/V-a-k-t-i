import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_typography.dart';
import '../../data/models/category.dart';
import '../../data/models/content_pillar.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/vakti_screen_title.dart';

/// Browse tab: categories grouped by pillar in a tinted grid (§7.3).
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          VaktiScreenTitle(l.browseTitle),
          const SizedBox(height: 12),
          _Section(
            title: l.pillarWellness,
            categories: categoriesForPillar(ContentPillar.wellness),
          ),
          const SizedBox(height: 8),
          _Section(
            title: l.pillarCommunication,
            categories: categoriesForPillar(ContentPillar.communication),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.categories});

  final String title;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: AppTypography.titleL),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            for (final c in categories)
              CategoryTile(
                category: c,
                onTap: () => context.push('/browse/${c.id}'),
              ),
          ],
        ),
      ],
    );
  }
}
