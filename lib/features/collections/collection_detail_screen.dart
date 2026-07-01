import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tip_collection.dart';
import '../../data/repositories/collections_repository.dart';
import '../../data/repositories/tip_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/favorite_card.dart';

/// The tips inside a single collection.
class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final collections = ref.watch(collectionsProvider);
    final repoAsync = ref.watch(tipRepositoryProvider);
    TipCollection? collection;
    for (final c in collections) {
      if (c.id == collectionId) {
        collection = c;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(collection?.name ?? '—')),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          final ids = collection?.tipIds ?? const [];
          final tips = [
            for (final id in ids)
              if (repo.byId(id) != null) repo.byId(id)!,
          ];
          if (tips.isEmpty) {
            return EmptyState(
              emoji: '📑',
              title: l.collectionEmptyTitle,
              body: l.collectionEmptyBody,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: tips.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) => FavoriteCard(
              tip: tips[i],
              onTap: () => context.push('/tip/${tips[i].id}'),
            ),
          );
        },
      ),
    );
  }
}
