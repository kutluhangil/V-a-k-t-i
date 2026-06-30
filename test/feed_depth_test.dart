import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/app/app.dart';
import 'package:vakti/app/router.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/repositories/tip_repository.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/features/feed/feed_screen.dart';
import 'package:vakti/services/daily_tip_service.dart';

void main() {
  group('depthTransform', () {
    test('centered card is identity', () {
      final r = depthTransform(0);
      expect(r.scale, 1.0);
      expect(r.opacity, 1.0);
      expect(r.lag, 0.0);
    });

    test('incoming card below is identity', () {
      final r = depthTransform(1);
      expect(r.scale, 1.0);
      expect(r.opacity, 1.0);
      expect(r.lag, 0.0);
    });

    test('fully outgoing card recedes, fades out, and lags', () {
      final r = depthTransform(-1);
      expect(r.scale, closeTo(0.92, 1e-9));
      expect(r.opacity, 0.0);
      expect(r.lag, 1.0);
    });

    test('half-outgoing card is partway', () {
      final r = depthTransform(-0.5);
      expect(r.scale, closeTo(0.96, 1e-9));
      expect(r.opacity, closeTo(0.3, 1e-9));
      expect(r.lag, closeTo(0.5, 1e-9));
    });
  });

  group('feed swipe', () {
    late TipRepository repo;

    setUpAll(() {
      final raw = File('assets/data/tips.json').readAsStringSync();
      final list = json.decode(raw) as List<dynamic>;
      repo = TipRepository(
        list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList(),
      );
    });

    setUp(() {
      LocalStore.instance.initInMemory();
      LocalStore.instance.set(LocalStore.kOnboardingDone, true);
      appRouter.go('/feed');
    });

    tearDown(() => LocalStore.instance.resetInMemory());

    testWidgets('renders first card and survives a vertical swipe',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tipRepositoryProvider.overrideWith((ref) => repo),
            dailyTipProvider.overrideWithValue(null),
          ],
          child: const VaktiApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ginger Tea'), findsOneWidget); // first card

      // Swipe up to the next card; should settle without throwing.
      await tester.fling(find.text('Ginger Tea'), const Offset(0, -600), 1000);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
