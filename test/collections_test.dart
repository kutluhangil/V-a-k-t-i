import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/models/tip_collection.dart';
import 'package:vakti/data/repositories/collections_repository.dart';
import 'package:vakti/data/repositories/tip_repository.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/features/collections/collection_detail_screen.dart';
import 'package:vakti/l10n/app_localizations.dart';

void main() {
  test('TipCollection round-trips through a map', () {
    final c = TipCollection(
      id: '1',
      name: 'Morning',
      createdAt: DateTime(2026, 7, 1, 8),
      tipIds: const ['a', 'b'],
    );
    final back = TipCollection.fromMap(c.id, c.toMap());
    expect(back.id, '1');
    expect(back.name, 'Morning');
    expect(back.createdAt, DateTime(2026, 7, 1, 8));
    expect(back.tipIds, ['a', 'b']);
  });

  group('CollectionsController', () {
    late ProviderContainer container;

    setUp(() {
      LocalStore.instance.initInMemory();
      container = ProviderContainer();
    });
    tearDown(() {
      container.dispose();
      LocalStore.instance.resetInMemory();
    });

    test('create then addTip (idempotent) and idsFor', () async {
      final ctrl = container.read(collectionsProvider.notifier);
      final id = await ctrl.create('Sleep');
      expect(container.read(collectionsProvider).single.name, 'Sleep');

      await ctrl.addTip(id, 'w_ginger_tea');
      await ctrl.addTip(id, 'w_ginger_tea'); // dup ignored
      expect(container.read(collectionsProvider).single.tipIds, ['w_ginger_tea']);
      expect(ctrl.idsFor('w_ginger_tea'), {id});
    });

    test('removeTip, rename, delete', () async {
      final ctrl = container.read(collectionsProvider.notifier);
      final id = await ctrl.create('X');
      await ctrl.addTip(id, 't1');
      await ctrl.removeTip(id, 't1');
      expect(container.read(collectionsProvider).single.tipIds, isEmpty);

      await ctrl.rename(id, 'Y');
      expect(container.read(collectionsProvider).single.name, 'Y');

      await ctrl.delete(id);
      expect(container.read(collectionsProvider), isEmpty);
    });
  });

  group('collection detail widget', () {
    late TipRepository repo;

    setUpAll(() {
      final raw = File('assets/data/tips.json').readAsStringSync();
      final list = json.decode(raw) as List<dynamic>;
      repo = TipRepository(
        list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList(),
      );
    });

    testWidgets('renders the tips in a collection', (tester) async {
      LocalStore.instance.initInMemory();
      final container = ProviderContainer(
        overrides: [tipRepositoryProvider.overrideWith((ref) => repo)],
      );
      final id = await container.read(collectionsProvider.notifier).create('C');
      await container
          .read(collectionsProvider.notifier)
          .addTip(id, 'w_ginger_tea');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('tr')],
            home: CollectionDetailScreen(collectionId: id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ginger Tea'), findsOneWidget);

      container.dispose();
      LocalStore.instance.resetInMemory();
    });
  });
}
