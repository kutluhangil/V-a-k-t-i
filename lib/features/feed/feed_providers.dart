import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/content_pillar.dart';
import '../../data/models/tip.dart';
import '../../data/repositories/tip_repository.dart';

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

/// The tips shown in the feed, filtered by the active pillar.
/// Empty while the repository is still loading.
final feedTipsProvider = Provider<List<Tip>>((ref) {
  final repo = ref.watch(tipRepositoryProvider).asData?.value;
  if (repo == null) return const [];
  final pillar = ref.watch(pillarFilterProvider);
  return pillar == null ? repo.all() : repo.byPillar(pillar);
});
