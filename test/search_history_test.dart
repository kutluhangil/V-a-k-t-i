import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/features/browse/search_history_provider.dart';

void main() {
  late ProviderContainer container;
  SearchHistoryController ctrl() =>
      container.read(searchHistoryProvider.notifier);
  SearchHistory state() => container.read(searchHistoryProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('record normalizes and ignores empty', () {
    ctrl().record('  Sleep  ');
    ctrl().record('   ');
    expect(state().recent, ['sleep']);
    expect(state().counts, {'sleep': 1});
  });

  test('recent dedupes, most-recent-first, capped at 5', () {
    for (final q in ['a', 'b', 'c', 'd', 'e', 'f']) {
      ctrl().record(q);
    }
    expect(state().recent, ['f', 'e', 'd', 'c', 'b']);
    ctrl().record('c');
    expect(state().recent.first, 'c');
    expect(state().recent.length, 5);
  });

  test('popular sorts by count desc then alphabetical, capped at 5', () {
    for (final q in ['sleep', 'sleep', 'sleep']) {
      ctrl().record(q);
    }
    for (final q in ['water', 'water']) {
      ctrl().record(q);
    }
    ctrl().record('zinc');
    ctrl().record('acid');
    for (final q in ['b1', 'b2', 'b3', 'b4', 'b5', 'b6']) {
      ctrl().record(q);
    }
    final pop = state().popular;
    expect(pop.first, 'sleep');
    expect(pop[1], 'water');
    expect(pop.length, 5);
  });

  test('removeRecent and clearRecent leave counts intact', () {
    ctrl().record('sleep');
    ctrl().record('water');
    ctrl().removeRecent('sleep');
    expect(state().recent, ['water']);
    expect(state().counts, {'sleep': 1, 'water': 1});
    ctrl().clearRecent();
    expect(state().recent, isEmpty);
    expect(state().counts, {'sleep': 1, 'water': 1});
  });
}
