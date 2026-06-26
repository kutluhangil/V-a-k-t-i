import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/repositories/tip_repository.dart';
import 'package:vakti/features/browse/search_provider.dart';

void main() {
  late TipRepository repo;

  setUpAll(() {
    final raw = File('assets/data/tips.json').readAsStringSync();
    final list = json.decode(raw) as List<dynamic>;
    repo = TipRepository(
      list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList(),
    );
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [tipRepositoryProvider.overrideWith((ref) async => repo)],
  );

  test('empty query returns nothing', () {
    final c = makeContainer();
    addTearDown(c.dispose);
    expect(c.read(searchResultsProvider), isEmpty);
  });

  test('query matches across languages, case-insensitive', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(tipRepositoryProvider.future); // resolve the async repo

    c.read(searchQueryProvider.notifier).set('GINGER');
    final results = c.read(searchResultsProvider);
    expect(results, isNotEmpty);
    expect(
      results.any((t) => t.title.en.toLowerCase().contains('ginger')),
      isTrue,
    );
  });

  test('nonsense query returns nothing', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    await c.read(tipRepositoryProvider.future);

    c.read(searchQueryProvider.notifier).set('zzzqqq-not-a-word');
    expect(c.read(searchResultsProvider), isEmpty);
  });
}
