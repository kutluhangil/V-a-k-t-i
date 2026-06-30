# Streak Calendar + Milestones Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated streak screen (90-day activity grid + 3/7/30/100 milestone badges) and a one-time full-screen celebration when a milestone is crossed.

**Architecture:** Extend the existing pure `StreakService` with day-history and milestone helpers; widen `StreakState`/`StreakController` to persist an active-day set and celebrated-milestone set in Hive. A new `features/streak/` screen renders the grid + badges. A listener in `app.dart` watches the streak provider and shows the celebration overlay over the root navigator.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3 (`Notifier`/`NotifierProvider`), go_router, Hive (via `LocalStore`), gen-l10n ARB (TR + EN).

## Global Constraints

- Offline-first: no backend, no network, no analytics. All state via `LocalStore`.
- Riverpod 3 only: `Notifier` / `NotifierProvider`; set `state` BEFORE awaiting Hive.
- `AsyncValue` has no `valueOrNull` → use `.asData?.value`.
- **Do NOT run `flutter analyze`** (crashes on Turkish `İ` in repo path). Use
  `dart analyze lib test`. `flutter test` is fine.
- Widget tests use `LocalStore.instance.initInMemory()` — never real Hive (fake-async
  deadlock). Reset global `appRouter` (`appRouter.go('/feed')`) and set
  `onboardingDone=true` in `setUp` if pumping the shell.
- l10n: every user string lives in BOTH `lib/l10n/app_en.arb` and `app_tr.arb`; run
  `flutter gen-l10n` after editing ARB. Access via `AppLocalizations.of(context)`.
- Brand: single saffron accent (`AppColors.saffron` / `saffronDeep`), no shadows,
  cards r20, inner r16, pills r999. Reuse `AppTypography`.
- Milestones are exactly `[3, 7, 30, 100]`. Day history window is 120 days.

---

### Task 1: Streak data layer — day history + milestone logic

Extend the pure service and the persisted controller. Pure helpers are unit-tested;
controller persistence mirrors the existing `kInterests` List storage pattern.

**Files:**
- Modify: `lib/services/streak_service.dart`
- Modify: `lib/data/sources/local_store.dart` (add two keys)
- Test: `test/streak_test.dart` (extend)

**Interfaces:**
- Consumes: existing `StreakService.dayKey(DateTime)`, `nextCount(...)`,
  `LocalStore.instance.get<T>/set<T>`, keys `kStreakCount/kStreakBest/kStreakLastDate`.
- Produces:
  - `const List<int> StreakService.milestones = [3, 7, 30, 100];`
  - `int? StreakService.pendingMilestone({required int current, required Set<int> celebrated})`
    → largest milestone `<= current` not in `celebrated`, else `null`.
  - `List<String> StreakService.pruneDays(Iterable<String> days, {required DateTime today, int windowDays = 120})`
    → unique day keys within the window, ascending.
  - `StreakState{ int current; int best; Set<String> activeDays; Set<int> celebratedMilestones }`.
  - `StreakController.celebrate(int milestone)` → marks every milestone `<= milestone`
    celebrated and persists.
  - `LocalStore.kStreakDays` (`'streakDays'`), `LocalStore.kStreakMilestones`
    (`'streakMilestones'`).

- [ ] **Step 1: Write failing tests for the pure helpers**

Append to `test/streak_test.dart` (inside `main()`):

```dart
  group('milestones', () {
    test('pendingMilestone returns largest uncelebrated <= current', () {
      expect(s.pendingMilestone(current: 7, celebrated: {}), 7);
      expect(s.pendingMilestone(current: 10, celebrated: {}), 7);
      expect(s.pendingMilestone(current: 30, celebrated: {3, 7}), 30);
    });

    test('pendingMilestone is null when none crossed or all celebrated', () {
      expect(s.pendingMilestone(current: 2, celebrated: {}), isNull);
      expect(s.pendingMilestone(current: 7, celebrated: {3, 7}), isNull);
    });

    test('milestones are the agreed thresholds', () {
      expect(StreakService.milestones, [3, 7, 30, 100]);
    });
  });

  group('pruneDays', () {
    test('drops days older than the window, dedupes, sorts ascending', () {
      final days = [
        key(today),
        key(today.subtract(const Duration(days: 5))),
        key(today.subtract(const Duration(days: 5))), // dup
        key(today.subtract(const Duration(days: 200))), // out of window
      ];
      final pruned = s.pruneDays(days, today: today);
      expect(pruned, [
        key(today.subtract(const Duration(days: 5))),
        key(today),
      ]);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/streak_test.dart`
Expected: FAIL — `pendingMilestone`/`pruneDays`/`milestones` not defined.

- [ ] **Step 3: Implement the pure helpers**

In `lib/services/streak_service.dart`, inside `class StreakService`, add after
`nextCount`:

```dart
  static const List<int> milestones = [3, 7, 30, 100];

  /// Largest milestone reached ([<= current]) that has not been celebrated yet,
  /// or null. Returning the largest means an upgrade with an existing streak
  /// celebrates once (for the highest passed milestone), not once per threshold.
  int? pendingMilestone({
    required int current,
    required Set<int> celebrated,
  }) {
    int? hit;
    for (final m in milestones) {
      if (m <= current && !celebrated.contains(m)) hit = m;
    }
    return hit;
  }

  /// Unique day keys within the last [windowDays] days (inclusive), ascending.
  List<String> pruneDays(
    Iterable<String> days, {
    required DateTime today,
    int windowDays = 120,
  }) {
    final cutoff = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: windowDays));
    final kept = <String>{};
    for (final d in days) {
      final parsed = DateTime.tryParse(d);
      if (parsed == null) continue;
      if (!parsed.isBefore(cutoff)) kept.add(d);
    }
    final sorted = kept.toList()..sort();
    return sorted;
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/streak_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Add the LocalStore keys**

In `lib/data/sources/local_store.dart`, after the `kStreakLastDate` line:

```dart
  static const kStreakDays = 'streakDays'; // List<String> active day keys (yyyy-MM-dd)
  static const kStreakMilestones = 'streakMilestones'; // List<int> celebrated thresholds
```

- [ ] **Step 6: Widen StreakState and the controller**

Replace `class StreakState` with:

```dart
class StreakState {
  final int current;
  final int best;
  final Set<String> activeDays;
  final Set<int> celebratedMilestones;

  const StreakState({
    required this.current,
    required this.best,
    this.activeDays = const {},
    this.celebratedMilestones = const {},
  });

  static const zero = StreakState(current: 0, best: 0);
}
```

In `StreakController.build()`, hydrate the new sets:

```dart
  @override
  StreakState build() {
    final days = (_store.get<List<dynamic>>(LocalStore.kStreakDays) ?? const [])
        .map((e) => e.toString())
        .toSet();
    final celebrated =
        (_store.get<List<dynamic>>(LocalStore.kStreakMilestones) ?? const [])
            .map((e) => int.parse(e.toString()))
            .toSet();
    return StreakState(
      current: _store.get<int>(LocalStore.kStreakCount, defaultValue: 0) ?? 0,
      best: _store.get<int>(LocalStore.kStreakBest, defaultValue: 0) ?? 0,
      activeDays: days,
      celebratedMilestones: celebrated,
    );
  }
```

Replace the body of `recordToday` (keep the early-return guard) with:

```dart
  Future<void> recordToday([DateTime? now]) async {
    final today = now ?? DateTime.now();
    final todayKey = StreakService.dayKey(today);
    final last = _store.get<String>(LocalStore.kStreakLastDate);
    if (last == todayKey) return; // already counted today

    final next = streakService.nextCount(
      lastDayKey: last,
      currentCount: state.current,
      today: today,
    );
    final best = next > state.best ? next : state.best;
    final days = streakService
        .pruneDays({...state.activeDays, todayKey}, today: today)
        .toSet();

    state = StreakState(
      current: next,
      best: best,
      activeDays: days,
      celebratedMilestones: state.celebratedMilestones,
    );
    await _store.set(LocalStore.kStreakCount, next);
    await _store.set(LocalStore.kStreakBest, best);
    await _store.set(LocalStore.kStreakLastDate, todayKey);
    await _store.set(LocalStore.kStreakDays, days.toList());
  }

  /// Marks every milestone at or below [milestone] celebrated so smaller
  /// thresholds never pop later, and persists.
  Future<void> celebrate(int milestone) async {
    final celebrated = {
      ...state.celebratedMilestones,
      ...StreakService.milestones.where((m) => m <= milestone),
    };
    state = StreakState(
      current: state.current,
      best: state.best,
      activeDays: state.activeDays,
      celebratedMilestones: celebrated,
    );
    await _store.set(LocalStore.kStreakMilestones, celebrated.toList());
  }
```

- [ ] **Step 7: Run the full suite and analyze**

Run: `flutter test && dart analyze lib test`
Expected: all tests PASS; analyze reports no issues.

- [ ] **Step 8: Commit**

```bash
git add lib/services/streak_service.dart lib/data/sources/local_store.dart test/streak_test.dart
git commit -m "feat(streak): day history + milestone logic in streak service"
```

---

### Task 2: l10n strings for the streak screen + celebration

Add every new user-facing string to both ARB files and regenerate.

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_tr.arb`

**Interfaces:**
- Produces (on `AppLocalizations`): `streakScreenTitle`, `streakGridTitle`,
  `streakMilestonesTitle`, `streakNextTarget(int remaining, int target)`,
  `streakAllMilestones`, `streakRule`, `streakCelebrationTitle(int days)`,
  `streakCelebrationBody`, `streakCelebrateDismiss`.

- [ ] **Step 1: Add strings to `app_en.arb`**

After the existing `"streakNone"` line (and its trailing comma), insert:

```json
  "streakScreenTitle": "Your streak",
  "streakGridTitle": "Last 90 days",
  "streakMilestonesTitle": "Milestones",
  "streakNextTarget": "{remaining} days to {target}",
  "@streakNextTarget": { "placeholders": { "remaining": { "type": "int" }, "target": { "type": "int" } } },
  "streakAllMilestones": "All milestones reached 🎉",
  "streakRule": "Open Vakti once a day to keep your streak going.",
  "streakCelebrationTitle": "{days}-day streak!",
  "@streakCelebrationTitle": { "placeholders": { "days": { "type": "int" } } },
  "streakCelebrationBody": "You showed up. Keep the rhythm going.",
  "streakCelebrateDismiss": "Continue",
```

- [ ] **Step 2: Add the same keys to `app_tr.arb`**

After the Turkish `"streakNone"` line, insert:

```json
  "streakScreenTitle": "Serin",
  "streakGridTitle": "Son 90 gün",
  "streakMilestonesTitle": "Kilometre taşları",
  "streakNextTarget": "{target} güne {remaining} gün kaldı",
  "@streakNextTarget": { "placeholders": { "remaining": { "type": "int" }, "target": { "type": "int" } } },
  "streakAllMilestones": "Tüm hedefler tamam 🎉",
  "streakRule": "Serini sürdürmek için Vakti'yi günde bir kez aç.",
  "streakCelebrationTitle": "{days} günlük seri!",
  "@streakCelebrationTitle": { "placeholders": { "days": { "type": "int" } } },
  "streakCelebrationBody": "Buradasın. Ritmi koru.",
  "streakCelebrateDismiss": "Devam",
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: no errors; `lib/l10n/app_localizations*.dart` updated.

- [ ] **Step 4: Verify it compiles**

Run: `dart analyze lib`
Expected: no issues (new getters/methods exist on `AppLocalizations`).

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_tr.arb lib/l10n/app_localizations*.dart
git commit -m "feat(streak): l10n strings for streak screen + celebration"
```

---

### Task 3: Streak screen — hero, 90-day grid, milestone badges + entry points

Build the screen, register the `/streak` route, and make the feed 🔥 chip and the
Settings streak banner tap into it.

**Files:**
- Create: `lib/features/streak/streak_screen.dart`
- Modify: `lib/app/router.dart` (add `/streak` route)
- Modify: `lib/features/feed/feed_screen.dart` (make `_StreakChip` tappable)
- Modify: `lib/features/settings/settings_screen.dart` (make `_StreakBanner` tappable)
- Test: `test/streak_screen_test.dart` (create)

**Interfaces:**
- Consumes: `streakProvider` → `StreakState{current,best,activeDays,celebratedMilestones}`,
  `StreakService.milestones`, `StreakService.dayKey`, `AppColors`, `AppTypography`,
  the Task 2 l10n getters, `widgets/time_arc.dart`.
- Produces: `class StreakScreen extends ConsumerWidget` at route `/streak`.

- [ ] **Step 1: Write a failing widget test**

Create `test/streak_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/features/streak/streak_screen.dart';
import 'package:vakti/l10n/app_localizations.dart';
import 'package:vakti/services/streak_service.dart';

Widget _host(StreakState state) {
  return ProviderScope(
    overrides: [
      streakProvider.overrideWith(() => _FakeStreak(state)),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('tr')],
      home: StreakScreen(),
    ),
  );
}

class _FakeStreak extends StreakController {
  _FakeStreak(this._state);
  final StreakState _state;
  @override
  StreakState build() => _state;
}

void main() {
  testWidgets('renders current count and milestone badges', (tester) async {
    await tester.pumpWidget(_host(const StreakState(
      current: 8,
      best: 12,
      activeDays: {},
      celebratedMilestones: {3, 7},
    )));
    await tester.pumpAndSettle();

    expect(find.text('8 days'), findsOneWidget); // hero count (streakDays)
    expect(find.text('Milestones'), findsOneWidget);
    expect(find.text('22 days to 30'), findsOneWidget); // next target: 30-8=22
  });
}
```

- [ ] **Step 2: Run it to verify failure**

Run: `flutter test test/streak_screen_test.dart`
Expected: FAIL — `streak_screen.dart` / `StreakScreen` does not exist.

- [ ] **Step 3: Implement the screen**

Create `lib/features/streak/streak_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/streak_service.dart';

/// Dedicated streak surface: hero count, 90-day activity grid, milestone badges.
class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(streakProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.streakScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Hero(current: s.current, best: s.best, l: l),
          const SizedBox(height: 28),
          _GroupLabel(l.streakGridTitle),
          const SizedBox(height: 12),
          _ActivityGrid(activeDays: s.activeDays),
          const SizedBox(height: 28),
          _GroupLabel(l.streakMilestonesTitle),
          const SizedBox(height: 12),
          _Milestones(current: s.current, l: l),
          const SizedBox(height: 24),
          Text(l.streakRule, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTypography.labelCaps);
}

class _Hero extends StatelessWidget {
  const _Hero({required this.current, required this.best, required this.l});
  final int current;
  final int best;
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.saffron.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current < 1 ? l.streakNone : l.streakDays(current),
                  style: AppTypography.titleL.copyWith(fontSize: 26),
                ),
                if (best > current && best > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.streakBest(best),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.saffronDeep),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 90-day grid, weeks as columns. Active day = saffron fill, today outlined,
/// empty = soft border. Read-only.
class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid({required this.activeDays});
  final Set<String> activeDays;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 89));
    // Build columns of 7 (one week each), oldest -> newest.
    final cells = <DateTime>[
      for (var i = 0; i < 90; i++) start.add(Duration(days: i)),
    ];
    final columns = <List<DateTime>>[];
    for (var i = 0; i < cells.length; i += 7) {
      columns.add(cells.sublist(i, (i + 7).clamp(0, cells.length)));
    }
    final todayKey = StreakService.dayKey(today);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in columns)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                children: [
                  for (final day in col)
                    _Cell(
                      active: activeDays.contains(StreakService.dayKey(day)),
                      isToday: StreakService.dayKey(day) == todayKey,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.active, required this.isToday});
  final bool active;
  final bool isToday;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.saffron : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isToday
              ? AppColors.saffronDeep
              : Theme.of(context).dividerColor,
          width: isToday ? 1.6 : 1,
        ),
      ),
    );
  }
}

class _Milestones extends StatelessWidget {
  const _Milestones({required this.current, required this.l});
  final int current;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final next = StreakService.milestones
        .where((m) => m > current)
        .fold<int?>(null, (acc, m) => acc ?? m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final m in StreakService.milestones)
              _Badge(days: m, unlocked: current >= m),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          next == null
              ? l.streakAllMilestones
              : l.streakNextTarget(next - current, next),
          style: AppTypography.bodyM.copyWith(color: AppColors.saffronDeep),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.days, required this.unlocked});
  final int days;
  final bool unlocked;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.saffron.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppColors.saffron
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            size: 18,
            color: unlocked ? AppColors.saffronDeep : Theme.of(context).hintColor,
          ),
          const SizedBox(height: 4),
          Text(
            '$days',
            style: AppTypography.bodyM.copyWith(
              fontWeight: FontWeight.w700,
              color: unlocked ? AppColors.saffronDeep : null,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the widget test to verify it passes**

Run: `flutter test test/streak_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Register the `/streak` route + expose the root navigator key**

In `lib/app/router.dart`, add the import near the other feature imports:

```dart
import '../features/streak/streak_screen.dart';
```

Rename the private `_rootNavigatorKey` to a public `rootNavigatorKey` so Task 4's
celebration listener can present over the root navigator. Change the declaration:

```dart
final rootNavigatorKey = GlobalKey<NavigatorState>();
```

and update its three existing usages in this file (`navigatorKey: rootNavigatorKey`
on the `GoRouter`, and `parentNavigatorKey: rootNavigatorKey` on the `/onboarding`
and `/tip/:id` routes).

Add this route inside the top-level `routes:` list, right after the `/tip/:id`
`GoRoute` (so it pushes full-screen over the shell):

```dart
    GoRoute(
      path: '/streak',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, _) => const StreakScreen(),
    ),
```

- [ ] **Step 6: Make the feed 🔥 chip tappable**

In `lib/features/feed/feed_screen.dart`, add the go_router import if missing
(`import 'package:go_router/go_router.dart';` is already present). Wrap the
`Container` returned by `_StreakChip.build` in an `InkWell`/`GestureDetector`:

Replace the `return Container(` … `);` body of `_StreakChip` with:

```dart
    return GestureDetector(
      onTap: () => context.push('/streak'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.saffron.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '🔥 $streak',
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.saffronDeep,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
```

- [ ] **Step 7: Make the Settings streak banner tappable**

In `lib/features/settings/settings_screen.dart`, add `import 'package:go_router/go_router.dart';`
if not present. Wrap the `_StreakBanner` `Container` in an `InkWell` with rounded
splash:

Change the start of `_StreakBanner.build` from `return Container(` to:

```dart
    return InkWell(
      onTap: () => context.push('/streak'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
```

and add a matching closing `)` for the `InkWell` at the end of the returned widget
(after the `Container`'s closing `)`).

- [ ] **Step 8: Run tests + analyze**

Run: `flutter test && dart analyze lib test`
Expected: all PASS; no analyze issues.

- [ ] **Step 9: Commit**

```bash
git add lib/features/streak/streak_screen.dart lib/app/router.dart lib/features/feed/feed_screen.dart lib/features/settings/settings_screen.dart test/streak_screen_test.dart
git commit -m "feat(streak): streak screen with 90-day grid, milestone badges, entry points"
```

---

### Task 4: Milestone celebration overlay + trigger

A full-screen celebration shown once when a new milestone is crossed, wired through a
listener in `app.dart` that watches the streak provider.

**Files:**
- Create: `lib/features/streak/streak_celebration.dart`
- Modify: `lib/app/app.dart` (wrap router output with the listener)
- Test: `test/streak_celebration_test.dart` (create)

**Interfaces:**
- Consumes: `streakProvider`, `StreakState`, `StreakService.milestones`,
  `StreakController.celebrate(int)`, `streakService.pendingMilestone(...)`,
  `widgets/time_arc.dart` (`TimeArc(position:, animate:)`), Task 2 l10n strings.
- Produces: `Future<void> showStreakCelebration(BuildContext, int milestone)`,
  `class StreakCelebrationListener extends ConsumerStatefulWidget` (wraps `child`).

- [ ] **Step 1: Write a failing widget test**

Create `test/streak_celebration_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/features/streak/streak_celebration.dart';
import 'package:vakti/l10n/app_localizations.dart';

void main() {
  testWidgets('celebration sheet shows milestone copy and dismisses',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showStreakCelebration(context, 7),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('7-day streak!'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('7-day streak!'), findsNothing);
  });
}
```

- [ ] **Step 2: Run it to verify failure**

Run: `flutter test test/streak_celebration_test.dart`
Expected: FAIL — `streak_celebration.dart` does not exist.

- [ ] **Step 3: Implement the celebration UI + listener**

Create `lib/features/streak/streak_celebration.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../services/streak_service.dart';
import '../../widgets/time_arc.dart';

/// Shows the full-screen milestone celebration. Returns when dismissed.
Future<void> showStreakCelebration(BuildContext context, int milestone) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'streak-celebration',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => _CelebrationSheet(milestone: milestone),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

class _CelebrationSheet extends StatelessWidget {
  const _CelebrationSheet({required this.milestone});
  final int milestone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TimeArc(position: 0.5, animate: true),
                const SizedBox(height: 20),
                const Text('🔥', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  l.streakCelebrationTitle(milestone),
                  textAlign: TextAlign.center,
                  style: AppTypography.titleL,
                ),
                const SizedBox(height: 8),
                Text(
                  l.streakCelebrationBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyM,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.streakCelebrateDismiss),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Watches the streak provider and presents the celebration once per crossed
/// milestone, then marks it celebrated. Wraps the app's router output.
class StreakCelebrationListener extends ConsumerStatefulWidget {
  const StreakCelebrationListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<StreakCelebrationListener> createState() =>
      _StreakCelebrationListenerState();
}

class _StreakCelebrationListenerState
    extends ConsumerState<StreakCelebrationListener> {
  bool _showing = false;

  Future<void> _maybeCelebrate(StreakState s) async {
    if (_showing) return;
    final milestone = streakService.pendingMilestone(
      current: s.current,
      celebrated: s.celebratedMilestones,
    );
    if (milestone == null) return;
    _showing = true;
    // Persist first so a restart mid-celebration won't re-fire.
    await ref.read(streakProvider.notifier).celebrate(milestone);
    // Present over the ROOT navigator: this listener sits above the router's
    // Navigator, so its own context has none. rootNavigatorKey does.
    final ctx = rootNavigatorKey.currentContext;
    if (!mounted || ctx == null) {
      _showing = false;
      return;
    }
    await showStreakCelebration(ctx, milestone);
    _showing = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StreakState>(streakProvider, (_, next) {
      _maybeCelebrate(next);
    });
    // Also check the initial state (recordToday in main runs before first build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeCelebrate(ref.read(streakProvider));
    });
    return widget.child;
  }
}
```

- [ ] **Step 4: Run the celebration test to verify it passes**

Run: `flutter test test/streak_celebration_test.dart`
Expected: PASS.

- [ ] **Step 5: Wire the listener into `app.dart`**

In `lib/app/app.dart`, add the import:

```dart
import '../features/streak/streak_celebration.dart';
```

Add a `builder` to `MaterialApp.router` that wraps the routed child:

```dart
      routerConfig: appRouter,
      builder: (context, child) =>
          StreakCelebrationListener(child: child ?? const SizedBox.shrink()),
```

- [ ] **Step 6: Run full suite + analyze**

Run: `flutter test && dart analyze lib test`
Expected: all PASS; no analyze issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/streak/streak_celebration.dart lib/app/app.dart test/streak_celebration_test.dart
git commit -m "feat(streak): one-time milestone celebration overlay + trigger"
```

---

## Notes for the implementer

- After all four tasks: `flutter test` (expect existing 16 + new tests green) and
  `dart analyze lib test` (clean). Optionally run on a device:
  `flutter run -d <device>` and tap the 🔥 chip to view `/streak`.
- The celebration only fires for streaks built up on this version onward, EXCEPT an
  existing streak ≥3 at upgrade will celebrate once for its highest passed milestone
  (intended — see `pendingMilestone` doc comment).
- Do not add new dependencies; everything uses what's already in `pubspec.yaml`.
