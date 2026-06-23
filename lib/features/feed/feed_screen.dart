import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/content_pillar.dart';
import '../../data/repositories/tip_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/tip_actions.dart';
import '../../widgets/tip_card.dart';
import 'feed_providers.dart';

/// The main feed: a vertical, full-screen PageView of tip cards with a pillar
/// filter pinned at the top (blueprint §7.2).
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repoAsync = ref.watch(tipRepositoryProvider);
    final pillar = ref.watch(pillarFilterProvider);
    final tips = ref.watch(feedTipsProvider);

    return SafeArea(
      child: Column(
        children: [
          _PillarFilter(selected: pillar, l: l),
          Expanded(
            child: repoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (_) => PageView.builder(
                key: ValueKey(pillar),
                scrollDirection: Axis.vertical,
                itemCount: tips.length,
                itemBuilder: (context, i) {
                  final tip = tips[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                          bottom: 28,
                          child: TipActions(tip: tip),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarFilter extends ConsumerWidget {
  const _PillarFilter({required this.selected, required this.l});

  final ContentPillar? selected;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(pillarFilterProvider.notifier);
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Chip(
            label: l.pillarAll,
            active: selected == null,
            onTap: () => controller.set(null),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: l.pillarWellness,
            active: selected == ContentPillar.wellness,
            onTap: () => controller.set(ContentPillar.wellness),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: l.pillarCommunication,
            active: selected == ContentPillar.communication,
            onTap: () => controller.set(ContentPillar.communication),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}
