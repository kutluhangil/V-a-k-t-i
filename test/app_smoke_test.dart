import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/app/app.dart';
import 'package:vakti/app/router.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/repositories/tip_repository.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/services/daily_tip_service.dart';
import 'package:vakti/widgets/tip_actions.dart';

// Widget tests run LocalStore in memory: Hive writes scheduled under the fake
// async clock never settle and would deadlock teardown (see LocalStore).

/// Phase-2 widget tests: feed renders + pillar filter, browse navigation, and
/// live locale switch from settings. The tip repository is overridden with a
/// disk-loaded copy to avoid real asset I/O under the fake async clock.
void main() {
  late TipRepository repo;

  setUpAll(() {
    final raw = File('assets/data/tips.json').readAsStringSync();
    final list = json.decode(raw) as List<dynamic>;
    final tips = list
        .map((e) => Tip.fromJson(e as Map<String, dynamic>))
        .toList();
    repo = TipRepository(tips);
  });

  setUp(() {
    LocalStore.instance.initInMemory();
    // Skip onboarding for the main flow tests (in-memory, sync write).
    LocalStore.instance.set(LocalStore.kOnboardingDone, true);
    // appRouter is a global singleton; reset its location between tests.
    appRouter.go('/feed');
  });

  tearDown(() {
    LocalStore.instance.resetInMemory();
  });

  Future<void> pumpApp(WidgetTester tester) async {
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
  }

  testWidgets('feed shows first tip and filters by pillar', (tester) async {
    await pumpApp(tester);

    // Default locale (en): first tip in asset order is Ginger Tea.
    expect(find.text('Ginger Tea'), findsOneWidget);

    // Filter to Communication -> page resets to the first communication tip.
    await tester.tap(find.text('Communication'));
    await tester.pumpAndSettle();

    expect(find.textContaining("won't do it for you"), findsOneWidget);
    expect(find.text('Ginger Tea'), findsNothing);
  });

  testWidgets('browse opens a category list', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Digestion'), findsWidgets);

    await tester.tap(
      find
          .ancestor(of: find.text('Digestion'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();
    // Category detail shows the digestion tips.
    expect(find.text('Ginger Tea'), findsWidgets);
  });

  testWidgets('settings switches language live', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsWidgets);
  });

  testWidgets('saving a tip shows it in favorites', (tester) async {
    await pumpApp(tester);

    // Tap the heart on the feed action rail (not the nav bar icon).
    final heart = find.descendant(
      of: find.byType(TipActions),
      matching: find.byIcon(Icons.favorite_border),
    );
    expect(heart, findsOneWidget);
    await tester.tap(heart);
    await tester.pumpAndSettle();

    // Open the Favorites tab; the saved tip (Ginger Tea) is listed.
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Ginger Tea'), findsWidgets);
  });

  testWidgets('first run shows onboarding', (tester) async {
    LocalStore.instance.resetInMemory(); // onboardingDone now false
    await pumpApp(tester);
    expect(find.textContaining('right thing'), findsOneWidget);
    expect(find.text('Ginger Tea'), findsNothing);
  });
}
