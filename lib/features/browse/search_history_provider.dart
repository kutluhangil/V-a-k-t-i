import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only search history + term frequency. In-memory only: nothing is
/// persisted to Hive/disk, and everything resets when the app restarts. Keeps
/// Vakti's offline / no-analytics posture intact.
class SearchHistory {
  const SearchHistory({this.recent = const [], this.counts = const {}});

  /// Last 5 distinct queries, most-recent-first.
  final List<String> recent;

  /// Session frequency of each normalized query.
  final Map<String, int> counts;

  /// Top 5 terms by count (desc), alphabetical tiebreak for stability.
  List<String> get popular {
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return entries.take(5).map((e) => e.key).toList(growable: false);
  }
}

class SearchHistoryController extends Notifier<SearchHistory> {
  @override
  SearchHistory build() => const SearchHistory();

  void record(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    final recent = [q, ...state.recent.where((e) => e != q)].take(5).toList();
    final counts = {...state.counts, q: (state.counts[q] ?? 0) + 1};
    state = SearchHistory(recent: recent, counts: counts);
  }

  void removeRecent(String query) {
    state = SearchHistory(
      recent: state.recent.where((e) => e != query).toList(),
      counts: state.counts,
    );
  }

  void clearRecent() {
    state = SearchHistory(recent: const [], counts: state.counts);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryController, SearchHistory>(
  SearchHistoryController.new,
);
