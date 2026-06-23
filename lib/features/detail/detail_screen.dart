import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/tip_repository.dart';
import '../../widgets/tip_actions.dart';
import '../../widgets/tip_card.dart';

/// Full single-card view, pushed over the shell. Hosts the save/share actions
/// and is the source of the shareable image (§7.4).
class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.tipId});

  final String tipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(tipRepositoryProvider);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: repoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (repo) {
            final tip = repo.byId(tipId);
            if (tip == null) {
              return const Center(child: Text('—'));
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Expanded(child: TipCard(tip: tip)),
                  const SizedBox(height: 16),
                  TipActions(tip: tip, axis: Axis.horizontal),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
