import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/tip_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tip_actions.dart';
import '../../widgets/tip_card.dart';

/// Favorites tab: the tips saved on-device, newest first (§7.5).
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repoAsync = ref.watch(tipRepositoryProvider);
    final favIds = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.favoritesTitle)),
      body: SafeArea(
        top: false,
        child: repoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: tips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final tip = tips[i];
                return SizedBox(
                  height: 480,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => context.push('/tip/${tip.id}'),
                          child: TipCard(tip: tip),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 20,
                        child: TipActions(tip: tip),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
