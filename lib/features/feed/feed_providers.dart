import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/content_pillar.dart';
import '../../data/models/tip.dart';
import '../../data/repositories/tip_repository.dart';
import '../settings/interests_provider.dart';

/// Active pillar filter for the feed. `null` = all pillars.
class PillarFilterController extends Notifier<ContentPillar?> {
  @override
  ContentPillar? build() => null;

  void set(ContentPillar? pillar) => state = pillar;
}

final pillarFilterProvider =
    NotifierProvider<PillarFilterController, ContentPillar?>(
      PillarFilterController.new,
    );

/// The tips shown in the feed, filtered by the active pillar and then ordered so
/// the user's chosen interest categories surface first (stable within groups).
/// Empty while the repository is still loading.
final feedTipsProvider = Provider<List<Tip>>((ref) {
  final repo = ref.watch(tipRepositoryProvider).asData?.value;
  if (repo == null) return const [];
  final pillar = ref.watch(pillarFilterProvider);
  final base = pillar == null ? repo.all() : repo.byPillar(pillar);

  final interests = ref.watch(interestsProvider);
  if (interests.isEmpty) return base;

  // Stable partition: interested categories keep their order, then the rest.
  final preferred = <Tip>[];
  final others = <Tip>[];
  for (final t in base) {
    (interests.contains(t.category) ? preferred : others).add(t);
  }
  return [...preferred, ...others];
});
