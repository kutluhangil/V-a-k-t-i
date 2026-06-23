import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../../data/repositories/tip_repository.dart';
import '../../widgets/tip_card.dart';

/// The tips inside one category, as a vertical list of cards (§7.3).
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = Localizations.localeOf(context).languageCode;
    final category = categoryById(categoryId);
    final repoAsync = ref.watch(tipRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == null
              ? ''
              : '${category.emoji}  ${category.title.of(lang)}',
        ),
      ),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (repo) {
          final tips = repo.byCategory(categoryId);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: tips.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) =>
                SizedBox(height: 480, child: TipCard(tip: tips[i])),
          );
        },
      ),
    );
  }
}
