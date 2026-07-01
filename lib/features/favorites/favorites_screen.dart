import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/tip_collection.dart';
import '../../data/repositories/collections_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/tip_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/favorite_card.dart';
import '../../widgets/vakti_screen_title.dart';
import '../../widgets/vakti_segmented.dart';

/// Favorites tab: saved tips and user collections, toggled by a segment.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _showCollections = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VaktiScreenTitle(l.favoritesTitle),
            const SizedBox(height: 16),
            VaktiSegmented<bool>(
              selected: _showCollections,
              onChanged: (v) => setState(() => _showCollections = v),
              segments: [
                VaktiSegment(false, l.favoritesSegment),
                VaktiSegment(true, l.collectionsSegment),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _showCollections
                  ? const _CollectionsView()
                  : const _FavoritesView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesView extends ConsumerWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repoAsync = ref.watch(tipRepositoryProvider);
    final favIds = ref.watch(favoritesProvider);
    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (repo) {
        final tips = repo.all().where((t) => favIds.contains(t.id)).toList();
        if (tips.isEmpty) {
          return EmptyState(
            emoji: '🤍',
            title: l.favoritesEmptyTitle,
            body: l.favoritesEmptyBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
          itemCount: tips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) => FavoriteCard(
            tip: tips[i],
            onTap: () => context.push('/tip/${tips[i].id}'),
          ),
        );
      },
    );
  }
}

class _CollectionsView extends ConsumerWidget {
  const _CollectionsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final collections = ref.watch(collectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _createDialog(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l.newCollection),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: collections.isEmpty
              ? EmptyState(
                  emoji: '📑',
                  title: l.collectionsEmptyTitle,
                  body: l.collectionsEmptyBody,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                  itemCount: collections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _CollectionRow(collection: collections[i]),
                ),
        ),
      ],
    );
  }
}

class _CollectionRow extends ConsumerWidget {
  const _CollectionRow({required this.collection});
  final TipCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/collection/${collection.id}'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: AppTypography.titleL.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.collectionCount(collection.tipIds.length),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.saffronDeep),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (v) {
                if (v == 'rename') _renameDialog(context, ref, collection);
                if (v == 'delete') {
                  ref.read(collectionsProvider.notifier).delete(collection.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'rename', child: Text(l.renameCollection)),
                PopupMenuItem(value: 'delete', child: Text(l.deleteCollection)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _createDialog(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.newCollection),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l.collectionNameHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l.createAction),
        ),
      ],
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    await ref.read(collectionsProvider.notifier).create(name);
  }
}

Future<void> _renameDialog(
  BuildContext context,
  WidgetRef ref,
  TipCollection collection,
) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController(text: collection.name);
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.renameCollection),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l.collectionNameHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l.saveAction),
        ),
      ],
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    await ref.read(collectionsProvider.notifier).rename(collection.id, name);
  }
}
