import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/app/app.dart';
import 'package:vakti/app/router.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/repositories/tip_repository.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/features/feed/feed_providers.dart';
import 'package:vakti/services/daily_tip_service.dart';

void main() {
  late List<Tip> tips;

  setUpAll(() {
    final raw = File('assets/data/tips.json').readAsStringSync();
    final list = json.decode(raw) as List<dynamic>;
    tips = list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList();
  });

  group('pinFirst', () {
    test('moves daily to front and removes the duplicate', () {
      final three = tips.take(3).toList();
      final result = pinFirst(three, three[1]);
      expect(result.map((t) => t.id).toList(),
          [three[1].id, three[0].id, three[2].id]);
    });

    test('null daily leaves the list unchanged', () {
      final three = tips.take(3).toList();
      expect(pinFirst(three, null), three);
    });

    test('daily not already in the list is still prepended', () {
      final slice = tips.sublist(5, 8); // does not include tips[0]
      final result = pinFirst(slice, tips[0]);
      expect(result.first.id, tips[0].id);
      expect(result.length, slice.length + 1);
    });
  });

  group('today badge', () {
    late TipRepository repo;

    setUpAll(() => repo = TipRepository(tips));

    setUp(() {
      LocalStore.instance.initInMemory();
      LocalStore.instance.set(LocalStore.kOnboardingDone, true);
      appRouter.go('/feed');
    });

    tearDown(() => LocalStore.instance.resetInMemory());

    testWidgets('first feed card shows the Today\'s Card badge', (tester) async {
      // Daily = Ginger Tea (asset index 0) so the first card is deterministic.
      final ginger = tips.firstWhere((t) => t.id == 'w_ginger_tea');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tipRepositoryProvider.overrideWith((ref) => repo),
            dailyTipProvider.overrideWithValue(ginger),
          ],
          child: const VaktiApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today\'s Card'), findsOneWidget);
      expect(find.text('Ginger Tea'), findsOneWidget); // first card
    });
  });
}
