import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/tip_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/favorite_card.dart';
import '../../widgets/vakti_screen_title.dart';

/// Favorites tab: the tips saved on-device, newest first (§7.5).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repoAsync = ref.watch(tipRepositoryProvider);
    final favIds = ref.watch(favoritesProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VaktiScreenTitle(l.favoritesTitle),
            const SizedBox(height: 16),
            Expanded(
              child: repoAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (repo) {
                  final tips = repo
                      .all()
                      .where((t) => favIds.contains(t.id))
                      .toList();
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
                    itemBuilder: (context, i) {
                      final tip = tips[i];
                      return FavoriteCard(
                        tip: tip,
                        onTap: () => context.push('/tip/${tip.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
