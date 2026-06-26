import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/localized_text.dart';
import '../../data/models/tip.dart';
import '../../data/repositories/tip_repository.dart';

/// Current browse search query.
class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String q) => state = q;
  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryController, String>(SearchQueryController.new);

/// Tips matching the query. Matches both languages so results are found
/// regardless of the active UI language. Empty query -> no results.
final searchResultsProvider = Provider<List<Tip>>((ref) {
  final repo = ref.watch(tipRepositoryProvider).asData?.value;
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (repo == null || q.isEmpty) return const [];

  bool hit(LocalizedText t) =>
      t.tr.toLowerCase().contains(q) || t.en.toLowerCase().contains(q);

  return repo
      .all()
      .where((t) => hit(t.title) || hit(t.primary) || hit(t.secondary))
      .toList(growable: false);
});
