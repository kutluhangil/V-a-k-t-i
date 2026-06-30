# Detail Hero Parallax Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a subtle parallax to the detail-screen hero image (lag on scroll, gentle zoom on pull-down) while keeping the editorial title-below layout.

**Architecture:** A pure `heroParallax(scrollOffset, maxShift)` helper returns the image's translate/scale. `_DetailBody` becomes a `StatefulWidget` owning a `ScrollController`; the hero block is extracted into a `_ParallaxHero` widget that rebuilds from the controller via `AnimatedBuilder`. Reduced-motion renders the current static hero.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3, go_router.

## Global Constraints

- Offline-first; no backend, no analytics. No new dependencies.
- **Do NOT run `flutter analyze`** (crashes on Turkish `İ` path). Use
  `dart analyze lib test`. `flutter test` is fine.
- Widget tests use `LocalStore.instance.initInMemory()` when pumping the app; this
  test pumps `DetailScreen` directly with an overridden `tipRepositoryProvider`, so no
  router/onboarding setup is needed.
- No gradient scrim, no SliverAppBar restructure, no time-arc change.
- Fixed constants: parallax factor `0.3`, `maxShift = 48`, zoom factor `0.0015`,
  zoom clamp `[1.0, 1.12]`, hero aspect `1.4`, corner `r20`.

---

### Task 1: `heroParallax` helper + parallax hero on the detail screen

**Files:**
- Modify: `lib/features/detail/detail_screen.dart`
- Test: `test/detail_hero_test.dart` (create)

**Interfaces:**
- Consumes: `tipRepositoryProvider`, `_HeroFallback` (already in this file),
  `categoryById`, `AppColors`, `TipActions`, `Tip`.
- Produces: top-level `({double dy, double scale}) heroParallax(double scrollOffset, double maxShift)`;
  `_ParallaxHero` widget.

- [ ] **Step 1: Write failing pure tests for `heroParallax`**

Create `test/detail_hero_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/features/detail/detail_screen.dart';

void main() {
  group('heroParallax', () {
    test('at rest is identity', () {
      final r = heroParallax(0, 48);
      expect(r.dy, 0.0);
      expect(r.scale, 1.0);
    });

    test('scrolling up lags the image, clamped to maxShift', () {
      expect(heroParallax(100, 48).dy, closeTo(30, 1e-9)); // 100 * 0.3
      expect(heroParallax(1000, 48).dy, 48.0); // clamped
      expect(heroParallax(100, 48).scale, 1.0);
    });

    test('pull-down overscroll zooms in, clamped at 1.12', () {
      final small = heroParallax(-20, 48);
      expect(small.dy, 0.0);
      expect(small.scale, closeTo(1.03, 1e-9)); // 1 + 20*0.0015
      expect(heroParallax(-1000, 48).scale, 1.12); // clamped
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/detail_hero_test.dart`
Expected: FAIL — `heroParallax` not defined.

- [ ] **Step 3: Implement `heroParallax`**

In `lib/features/detail/detail_screen.dart`, add at the bottom of the file
(top-level):

```dart
/// Translate (`dy`) and `scale` for the detail hero image given the scroll
/// offset. Scrolling up (offset > 0) lags the image behind the frame; pulling
/// down (offset < 0) zooms it in gently. Pure — unit-testable.
({double dy, double scale}) heroParallax(double scrollOffset, double maxShift) {
  if (scrollOffset >= 0) {
    return (dy: (scrollOffset * 0.3).clamp(0.0, maxShift), scale: 1.0);
  }
  return (dy: 0.0, scale: (1.0 - scrollOffset * 0.0015).clamp(1.0, 1.12));
}
```

- [ ] **Step 4: Run pure tests to verify they pass**

Run: `flutter test test/detail_hero_test.dart`
Expected: PASS (all three `heroParallax` tests).

- [ ] **Step 5: Convert `_DetailBody` to stateful and add a `ScrollController`**

In `lib/features/detail/detail_screen.dart`, change the `_DetailBody` declaration
from a `StatelessWidget` to a `StatefulWidget` owning a `ScrollController`, and attach
it to the `CustomScrollView`. Keep the entire `build` body identical except for adding
`controller: _scroll` to the `CustomScrollView`.

Replace:

```dart
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.tip});
  final Tip tip;

  @override
  Widget build(BuildContext context) {
```

with:

```dart
class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.tip});
  final Tip tip;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
```

Then add the controller to the `CustomScrollView`. Change:

```dart
    return CustomScrollView(
      slivers: [
```

to:

```dart
    return CustomScrollView(
      controller: _scroll,
      slivers: [
```

(Inside this `build`, every existing `tip` reference now resolves to the local
`final tip = widget.tip;` line just added — no other edits needed there.)

- [ ] **Step 6: Swap the static hero for `_ParallaxHero`**

In the same `build`, replace the hero `ClipRRect` block:

```dart
                  // ── Hero image ─────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: Image.asset(
                        'assets/images/cards/${tip.id}.webp',
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stack) => _HeroFallback(
                          tip: tip,
                          tint: tint,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
```

with:

```dart
                  // ── Hero image (parallax) ──────────────────────────────
                  _ParallaxHero(
                    tip: tip,
                    tint: tint,
                    isDark: isDark,
                    controller: _scroll,
                  ),
```

- [ ] **Step 7: Add the `_ParallaxHero` widget**

Add at the bottom of `lib/features/detail/detail_screen.dart` (top-level), next to
`_HeroFallback`:

```dart
/// The detail hero image with a scroll-driven parallax. Keeps the rounded card
/// framing; the image lags on scroll-up and zooms gently on pull-down. Falls
/// back to [_HeroFallback] when the asset is missing, and to a static image
/// when the platform requests reduced motion.
class _ParallaxHero extends StatelessWidget {
  const _ParallaxHero({
    required this.tip,
    required this.tint,
    required this.isDark,
    required this.controller,
  });

  final Tip tip;
  final Color tint;
  final bool isDark;
  final ScrollController controller;

  static const _maxShift = 48.0;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/cards/${tip.id}.webp',
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) =>
          _HeroFallback(tip: tip, tint: tint, isDark: isDark),
    );

    if (MediaQuery.of(context).disableAnimations) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(aspectRatio: 1.4, child: image),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w / 1.4;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: w,
            height: h,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final offset = controller.hasClients ? controller.offset : 0.0;
                final p = heroParallax(offset, _maxShift);
                return OverflowBox(
                  minWidth: w,
                  maxWidth: w,
                  minHeight: h,
                  maxHeight: h + _maxShift,
                  alignment: Alignment.bottomCenter,
                  child: Transform.translate(
                    offset: Offset(0, p.dy),
                    child: Transform.scale(
                      scale: p.scale,
                      child: SizedBox(
                        width: w,
                        height: h + _maxShift,
                        child: image,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 8: Add a widget render/scroll smoke test**

Append to `test/detail_hero_test.dart` — add these imports at the top (with the
existing ones):

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/repositories/tip_repository.dart';
import 'package:vakti/l10n/app_localizations.dart';
```

And add this group inside `main()` (after the `heroParallax` group):

```dart
  group('detail render', () {
    late TipRepository repo;

    setUpAll(() {
      final raw = File('assets/data/tips.json').readAsStringSync();
      final list = json.decode(raw) as List<dynamic>;
      repo = TipRepository(
        list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList(),
      );
    });

    testWidgets('hero + title render and a scroll settles', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tipRepositoryProvider.overrideWith((ref) => repo)],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: [Locale('en'), Locale('tr')],
            home: DetailScreen(tipId: 'w_ginger_tea'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ginger Tea'), findsOneWidget); // title below the hero
      expect(find.byType(DetailScreen), findsOneWidget);

      // Drag the content up; the parallax builder must not throw.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
```

- [ ] **Step 9: Run the widget test**

Run: `flutter test test/detail_hero_test.dart`
Expected: PASS (`heroParallax` group + `detail render` group).

- [ ] **Step 10: Run the full suite + analyze**

Run: `flutter test && dart analyze lib test`
Expected: all PASS; analyze clean.

- [ ] **Step 11: Commit**

```bash
git add lib/features/detail/detail_screen.dart test/detail_hero_test.dart
git commit -m "feat(detail): scroll-driven parallax on the hero image"
```

---

## Notes for the implementer

- After the task: `flutter test` (existing + new green) and `dart analyze lib test`
  (clean). Optionally `flutter run -d <device>`, open a tip, and scroll — the hero
  lags behind the page and zooms slightly when you pull down; the title stays below.
- Reduced motion (`MediaQuery.disableAnimations`) renders the static hero.
- No new dependencies; the title-below editorial layout is unchanged.
