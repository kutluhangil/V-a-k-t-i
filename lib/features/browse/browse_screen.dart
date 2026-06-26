import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/category.dart';
import '../../data/models/content_pillar.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/favorite_card.dart';
import '../../widgets/vakti_screen_title.dart';
import 'search_provider.dart';

/// Browse tab: a search field over all tips, then categories grouped by pillar
/// in a tinted grid (§7.3). Typing swaps the grid for search results.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(searchQueryProvider);

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          VaktiScreenTitle(l.browseTitle),
          const SizedBox(height: 12),
          _SearchField(
            controller: _controller,
            hint: l.searchHint,
            onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
            onClear: () {
              _controller.clear();
              ref.read(searchQueryProvider.notifier).clear();
            },
          ),
          const SizedBox(height: 8),
          if (query.trim().isEmpty) ...[
            _Section(
              title: l.pillarWellness,
              categories: categoriesForPillar(ContentPillar.wellness),
            ),
            const SizedBox(height: 8),
            _Section(
              title: l.pillarCommunication,
              categories: categoriesForPillar(ContentPillar.communication),
            ),
          ] else
            const _SearchResults(),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.saffron, width: 1.5),
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final results = ref.watch(searchResultsProvider);

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: EmptyState(
          emoji: '🔍',
          title: l.searchEmptyTitle,
          body: l.searchEmptyBody,
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 4),
        for (final tip in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FavoriteCard(
              tip: tip,
              onTap: () => context.push('/tip/${tip.id}'),
            ),
          ),
      ],
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
