# "Today's Card" Hero Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pin the deterministic daily tip to the top of the feed and mark it with a "Today's Card" badge.

**Architecture:** A pure `pinFirst(tips, daily)` helper reorders the feed list; `feedTipsProvider` applies it using the existing `dailyTipProvider`. The feed's first card gets a saffron badge overlay. `TipCard` is untouched.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3 (`Provider`), go_router, gen-l10n ARB (TR + EN).

## Global Constraints

- Offline-first: no backend, no network, no analytics.
- Riverpod 3: `Provider` / `NotifierProvider`; `AsyncValue` → `.asData?.value`.
- **Do NOT run `flutter analyze`** (crashes on Turkish `İ` in repo path). Use
  `dart analyze lib test`. `flutter test` is fine.
- Widget tests use `LocalStore.instance.initInMemory()`; `setUp` resets the global
  `appRouter` (`appRouter.go('/feed')`) and sets `onboardingDone = true`.
- `dailyTipProvider` uses real `DateTime.now()` → it is **non-deterministic in tests**.
  Every widget test that pumps the app MUST override it (`overrideWithValue(...)`) so
  feed ordering is stable.
- l10n: every user string lives in BOTH `lib/l10n/app_en.arb` and `app_tr.arb`; run
  `flutter gen-l10n` after editing ARB. Access via `AppLocalizations.of(context)`.
- Badge copy: EN "Today's Card", TR "Günün Kartı". Badge style mirrors the streak chip
  (`r999`, `AppColors.saffron` @14% bg, `AppColors.saffronDeep` text,
  `AppTypography.labelCaps`, `w700`).
- `Tip` has a `final String id`.

---

### Task 1: `pinFirst` helper + `feedTipsProvider` ordering

Reorder the feed so the daily tip is first, and keep the existing smoke test green by
overriding the (date-dependent) `dailyTipProvider` to `null` there.

**Files:**
- Modify: `lib/features/feed/feed_providers.dart`
- Modify: `test/app_smoke_test.dart` (add a provider override in `pumpApp`)
- Test: `test/feed_today_test.dart` (create — pure `pinFirst` tests)

**Interfaces:**
- Consumes: `dailyTipProvider` (`Provider<Tip?>`) from
  `lib/services/daily_tip_service.dart`; existing `feedTipsProvider` body; `Tip.id`.
- Produces: top-level `List<Tip> pinFirst(List<Tip> tips, Tip? daily)`.

- [ ] **Step 1: Write failing pure tests for `pinFirst`**

Create `test/feed_today_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/features/feed/feed_providers.dart';

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
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/feed_today_test.dart`
Expected: FAIL — `pinFirst` not defined.

- [ ] **Step 3: Implement `pinFirst` and apply it in `feedTipsProvider`**

In `lib/features/feed/feed_providers.dart`, add the import at the top (with the other
imports):

```dart
import '../../services/daily_tip_service.dart';
```

Add the helper at the bottom of the file:

```dart
/// Returns [tips] with [daily] moved to the front (removing any duplicate of it).
/// If [daily] is null, returns [tips] unchanged. Pure — unit-testable.
List<Tip> pinFirst(List<Tip> tips, Tip? daily) {
  if (daily == null) return tips;
  return [daily, ...tips.where((t) => t.id != daily.id)];
}
```

Change the end of `feedTipsProvider`. It currently ends with two return paths
(`if (interests.isEmpty) return base;` and `return [...preferred, ...others];`). Wrap
both results in `pinFirst(..., ref.watch(dailyTipProvider))`:

Replace:

```dart
  final interests = ref.watch(interestsProvider);
  if (interests.isEmpty) return base;

  // Stable partition: interested categories keep their order, then the rest.
  final preferred = <Tip>[];
  final others = <Tip>[];
  for (final t in base) {
    (interests.contains(t.category) ? preferred : others).add(t);
  }
  return [...preferred, ...others];
});
```

with:

```dart
  final daily = ref.watch(dailyTipProvider);
  final interests = ref.watch(interestsProvider);
  if (interests.isEmpty) return pinFirst(base, daily);

  // Stable partition: interested categories keep their order, then the rest.
  final preferred = <Tip>[];
  final others = <Tip>[];
  for (final t in base) {
    (interests.contains(t.category) ? preferred : others).add(t);
  }
  return pinFirst([...preferred, ...others], daily);
});
```

- [ ] **Step 4: Run the pure tests to verify they pass**

Run: `flutter test test/feed_today_test.dart`
Expected: PASS (all three `pinFirst` tests).

- [ ] **Step 5: Keep the smoke test deterministic**

`test/app_smoke_test.dart` asserts "Ginger Tea" (asset index 0) is the first feed
card. With `pinFirst` the first card becomes the date-dependent daily tip, which would
break that test. Override `dailyTipProvider` to `null` in `pumpApp` so the order stays
as the asset order.

Add the import (with the other `package:vakti/...` imports):

```dart
import 'package:vakti/services/daily_tip_service.dart';
```

In `pumpApp`, change the `overrides` list:

```dart
      ProviderScope(
        overrides: [
          tipRepositoryProvider.overrideWith((ref) => repo),
          dailyTipProvider.overrideWithValue(null),
        ],
        child: const VaktiApp(),
      ),
```

- [ ] **Step 6: Run the full suite + analyze**

Run: `flutter test && dart analyze lib test`
Expected: all PASS (existing smoke tests green again); analyze clean.

- [ ] **Step 7: Commit**

```bash
git add lib/features/feed/feed_providers.dart test/feed_today_test.dart test/app_smoke_test.dart
git commit -m "feat(feed): pin daily tip to top of feed (pinFirst)"
```

---

### Task 2: "Today's Card" badge overlay + l10n

Add the localized string and render the badge over the first feed card.

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb`
- Modify: `lib/features/feed/feed_screen.dart`
- Test: `test/feed_today_test.dart` (extend — widget test for the badge)

**Interfaces:**
- Consumes: `AppLocalizations.feedTodayBadge`, `feedTipsProvider`, `dailyTipProvider`,
  `AppColors`, `AppTypography`.
- Produces: a `_TodayBadge` private widget in `feed_screen.dart`; the badge overlay on
  feed item `i == 0`.

- [ ] **Step 1: Add the l10n string (EN then TR)**

In `lib/l10n/app_en.arb`, after the `"dailyTipLabel": "Today's tip",` line, add:

```json
  "feedTodayBadge": "Today's Card",
```

In `lib/l10n/app_tr.arb`, after its `"dailyTipLabel"` line, add:

```json
  "feedTodayBadge": "Günün Kartı",
```

- [ ] **Step 2: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: no errors; `AppLocalizations` gains a `feedTodayBadge` getter.

- [ ] **Step 3: Write a failing widget test for the badge**

Append to `test/feed_today_test.dart` these imports at the top (with the existing
ones):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vakti/app/app.dart';
import 'package:vakti/app/router.dart';
import 'package:vakti/data/repositories/tip_repository.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/services/daily_tip_service.dart';
```

And add this group inside `main()` (after the `pinFirst` group):

```dart
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
```

- [ ] **Step 4: Run it to verify failure**

Run: `flutter test test/feed_today_test.dart`
Expected: FAIL — no "Today's Card" text yet.

- [ ] **Step 5: Render the badge overlay**

In `lib/features/feed/feed_screen.dart`, the feed `itemBuilder` returns a `Stack` with
a `Positioned.fill` `TipCard` and a `Positioned` `TipActions`. Add a third child,
shown only for the first card. Change the `Stack`'s `children` to:

```dart
                      children: [
                        Positioned.fill(
                          child: TipCard(
                            tip: tip,
                            onTap: () => context.push('/tip/${tip.id}'),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 28,
                          child: TipActions(tip: tip),
                        ),
                        if (i == 0)
                          Positioned(
                            left: 12,
                            top: 20,
                            child: _TodayBadge(label: l.feedTodayBadge),
                          ),
                      ],
```

Add the badge widget at the bottom of the file (mirrors the streak chip style):

```dart
/// Saffron pill marking the pinned daily card at the top of the feed.
class _TodayBadge extends StatelessWidget {
  const _TodayBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.saffron.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelCaps.copyWith(
          color: AppColors.saffronDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
```

`l` (the `AppLocalizations` instance) and `i` (the item index) are already in scope in
the `itemBuilder`. `AppColors` and `AppTypography` are already imported in this file.

- [ ] **Step 6: Run the widget test to verify it passes**

Run: `flutter test test/feed_today_test.dart`
Expected: PASS (badge + first-card assertions).

- [ ] **Step 7: Run the full suite + analyze**

Run: `flutter test && dart analyze lib test`
Expected: all PASS; analyze clean.

- [ ] **Step 8: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_tr.arb lib/l10n/app_localizations*.dart lib/features/feed/feed_screen.dart test/feed_today_test.dart
git commit -m "feat(feed): Today's Card badge on the pinned daily tip"
```

---

## Notes for the implementer

- After both tasks: `flutter test` (existing 16 + new pinFirst/badge tests green) and
  `dart analyze lib test` (clean). Optionally `flutter run -d <device>` — the top feed
  card shows the "Günün Kartı" / "Today's Card" badge.
- No new dependencies.
- This branch (`feature/today-card`) is independent of `feature/streak-calendar`; it
  was cut from `main` and does not include the streak screen work.
