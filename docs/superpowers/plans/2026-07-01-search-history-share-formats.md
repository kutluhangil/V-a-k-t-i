# Search History + Multi-Format Share Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add session-only search history + popular-term chips to the Browse tab, and let users pick a 4:5 / 9:16 / 1:1 share image via a bottom sheet.

**Architecture:** Feature A is a pure in-memory Riverpod `Notifier` (`SearchHistory`) surfaced as chips in `browse_screen` when the search field is empty — no persistence. Feature B introduces a `ShareFormat` enum, makes `ShareCard` format-aware with per-format layout numbers, and turns `ShareService.shareTip` into a bottom-sheet picker over the existing screenshot→file→SharePlus flow.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3 (`Notifier`/`NotifierProvider`), `screenshot`, `share_plus`, gen-l10n ARB.

## Global Constraints

- Analyze with `dart analyze lib test` — NEVER `flutter analyze` (Turkish-İ path crashes the analysis server).
- Riverpod 3: use `Notifier`/`NotifierProvider`; emit NEW immutable state objects (copy lists/maps) so provider equality fires.
- All user-facing strings go through gen-l10n ARB (`app_en.arb` + `app_tr.arb`), then `flutter gen-l10n`. Both languages required.
- Widget tests: `LocalStore.instance.initInMemory()` in setUp; reset `appRouter.go('/feed')` + `onboardingDone=true` per existing harness. These two features add NO Hive writes.
- Communication tip titles are quoted sentences (literal `"`) — use substring finders in tests.
- Colors from `AppColors`; pill radius 999, card r20, button r14. No shadows.
- Session-only: NOTHING from search is written to Hive/disk.

---

### Task 1: SearchHistory state (in-memory notifier)

**Files:**
- Create: `lib/features/browse/search_history_provider.dart`
- Test: `test/search_history_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `class SearchHistory { final List<String> recent; final Map<String,int> counts; const SearchHistory({this.recent = const [], this.counts = const {}}); List<String> get popular; }`
  - `class SearchHistoryController extends Notifier<SearchHistory>` with `void record(String query)`, `void removeRecent(String query)`, `void clearRecent()`.
  - `final searchHistoryProvider = NotifierProvider<SearchHistoryController, SearchHistory>(SearchHistoryController.new);`
  - `popular`: keys of `counts` sorted by count desc, alphabetical tiebreak, capped 5.
  - `record`: normalizes `query.trim().toLowerCase()`; ignores empty; dedupes + front-inserts into `recent` capped at 5; increments `counts`.

- [ ] **Step 1: Write the failing test**

Create `test/search_history_test.dart`:

```dart
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
    for (final q in ['sleep', 'sleep', 'sleep']) ctrl().record(q);
    for (final q in ['water', 'water']) ctrl().record(q);
    ctrl().record('zinc');
    ctrl().record('acid');
    for (final q in ['b1', 'b2', 'b3', 'b4', 'b5', 'b6']) ctrl().record(q);
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/search_history_test.dart`
Expected: FAIL — `search_history_provider.dart` / `SearchHistory` not found.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/browse/search_history_provider.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/search_history_test.dart`
Expected: PASS (4 tests). Then `dart analyze lib test` — clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/browse/search_history_provider.dart test/search_history_test.dart
git commit -m "feat(search): session-only search history + popular-term state"
```

---

### Task 2: l10n strings for search discovery

**Files:**
- Modify: `lib/l10n/app_en.arb` (before the final `tipsLoaded` block)
- Modify: `lib/l10n/app_tr.arb` (before the final `tipsLoaded` line)
- Generated: `lib/l10n/app_localizations*.dart` via `flutter gen-l10n`

**Interfaces:**
- Produces: `l.popularLabel`, `l.recentSearchesLabel`, `l.clearAll` on `AppLocalizations`.

- [ ] **Step 1: Add EN keys**

In `lib/l10n/app_en.arb`, insert before the `"tipsLoaded": "{count} tips loaded",` line:

```json
  "popularLabel": "Popular",
  "recentSearchesLabel": "Recent searches",
  "clearAll": "Clear",

```

- [ ] **Step 2: Add TR keys**

In `lib/l10n/app_tr.arb`, insert before the final `"tipsLoaded": "{count} bilgi yüklendi"` line (remember to keep JSON commas valid):

```json
  "popularLabel": "Popüler",
  "recentSearchesLabel": "Son aramalar",
  "clearAll": "Temizle",
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: no errors; `AppLocalizations` now exposes the three getters.

- [ ] **Step 4: Verify analyze**

Run: `dart analyze lib`
Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_tr.arb lib/l10n/app_localizations*.dart
git commit -m "i18n(search): add popular/recent/clear strings"
```

---

### Task 3: Search discovery chips in Browse

**Files:**
- Modify: `lib/features/browse/browse_screen.dart`
- Test: `test/browse_search_history_test.dart`

**Interfaces:**
- Consumes: `searchHistoryProvider` + `SearchHistoryController` (Task 1); `l.popularLabel/recentSearchesLabel/clearAll` (Task 2); existing `searchQueryProvider`.
- Produces: UI only.

Behavior added to `browse_screen.dart`:
1. Record on submit: give `_SearchField` an `onSubmitted` that calls
   `ref.read(searchHistoryProvider.notifier).record(v)`.
2. Record on result tap: in `_SearchResults`, before `context.push`, call
   `record(currentQuery)`.
3. When `query.trim().isEmpty`, render `_SearchDiscovery` above the category
   `_Section`s. Tapping a chip fills the field + sets the query.

- [ ] **Step 1: Write the failing widget test**

Create `test/browse_search_history_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/features/browse/browse_screen.dart';
import 'package:vakti/features/browse/search_history_provider.dart';
import 'package:vakti/l10n/app_localizations.dart';

Widget _host() => ProviderScope(
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: BrowseScreen()),
      ),
    );

void main() {
  setUp(() => LocalStore.instance.initInMemory());

  testWidgets('recent chips appear and re-run search on tap', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Type a query and submit -> recorded.
    await tester.enterText(find.byType(TextField), 'sleep');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Clear the field -> discovery chips should show 'sleep' under Recent.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'sleep'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/browse_search_history_test.dart`
Expected: FAIL — no 'Recent searches' text / no chip.

- [ ] **Step 3: Add onSubmitted to `_SearchField`**

In `lib/features/browse/browse_screen.dart`, add a field + wire it. Change the `_SearchField` class signature and `TextField`:

```dart
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
```

In its `TextField`, add `onSubmitted: onSubmitted,` next to `onChanged:`.

- [ ] **Step 4: Wire the callbacks + discovery block in `build`**

In `_BrowseScreenState.build`, update the `_SearchField(...)` call to pass `onSubmitted`, and add `_SearchDiscovery` in the empty-query branch. Replace the `_SearchField(...)` widget and the empty-query block:

```dart
          _SearchField(
            controller: _controller,
            hint: l.searchHint,
            onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
            onSubmitted: (v) =>
                ref.read(searchHistoryProvider.notifier).record(v),
            onClear: () {
              _controller.clear();
              ref.read(searchQueryProvider.notifier).clear();
            },
          ),
          const SizedBox(height: 8),
          if (query.trim().isEmpty) ...[
            _SearchDiscovery(
              onTap: (term) {
                _controller.text = term;
                ref.read(searchQueryProvider.notifier).set(term);
              },
            ),
            _Section(
              title: l.pillarWellness,
              categories: categoriesForPillar(ContentPillar.wellness),
            ),
            const SizedBox(height: 8),
            _Section(
              title: l.pillarCommunication,
              categories: categoriesForPillar(ContentPillar.communication),
            ),
          ] else
            const _SearchResults(),
```

Add the import at the top of the file:

```dart
import 'search_history_provider.dart';
```

- [ ] **Step 5: Record on result tap in `_SearchResults`**

In `_SearchResults.build`, capture the query and record before pushing. Replace the `onTap`:

```dart
    final query = ref.read(searchQueryProvider);
    // ...
            child: FavoriteCard(
              tip: tip,
              onTap: () {
                ref.read(searchHistoryProvider.notifier).record(query);
                context.push('/tip/${tip.id}');
              },
            ),
```

- [ ] **Step 6: Add the `_SearchDiscovery` widget**

Append to `browse_screen.dart`:

```dart
/// Popular + recent search chips, shown above the category grid when the
/// search field is empty. Session-only; hidden when there is nothing to show.
class _SearchDiscovery extends ConsumerWidget {
  const _SearchDiscovery({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final history = ref.watch(searchHistoryProvider);
    final popular = history.popular;
    final recent = history.recent;
    if (popular.isEmpty && recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (popular.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(l.popularLabel, style: AppTypography.labelCaps),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in popular)
                ActionChip(label: Text(term), onPressed: () => onTap(term)),
            ],
          ),
        ],
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.recentSearchesLabel, style: AppTypography.labelCaps),
                TextButton(
                  onPressed: () =>
                      ref.read(searchHistoryProvider.notifier).clearRecent(),
                  child: Text(l.clearAll),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final term in recent)
                ActionChip(
                  label: Text(term),
                  onPressed: () => onTap(term),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => ref
                      .read(searchHistoryProvider.notifier)
                      .removeRecent(term),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 7: Run tests + analyze**

Run: `flutter test test/browse_search_history_test.dart`
Expected: PASS.
Run: `dart analyze lib test`
Expected: clean.

- [ ] **Step 8: Commit**

```bash
git add lib/features/browse/browse_screen.dart test/browse_search_history_test.dart
git commit -m "feat(search): popular + recent search chips on Browse"
```

---

### Task 4: ShareFormat enum + format-aware ShareCard

**Files:**
- Modify: `lib/widgets/share_card.dart`
- Test: `test/share_card_test.dart`

**Interfaces:**
- Consumes: existing `Tip`, `AppColors`, `TimeArc`.
- Produces:
  - `enum ShareFormat { post, story, square }` with `Size get size` →
    post `1080×1350`, story `1080×1920`, square `1080×1080`.
  - `ShareCard({required Tip tip, required String lang, ShareFormat format = ShareFormat.post})`.
  - Removes the old `static const size`; callers use `format.size`.

- [ ] **Step 1: Write the failing test**

Create `test/share_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/content_pillar.dart';
import 'package:vakti/data/models/localized_text.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/widgets/share_card.dart';

Tip _tip() => const Tip(
      id: 't1',
      pillar: ContentPillar.wellness,
      category: 'sleep',
      emoji: '🌙',
      title: LocalizedText(tr: 'Uyku başlığı', en: 'Sleep title'),
      primaryLabel: LocalizedText(tr: 'NE ZAMAN', en: 'WHEN'),
      primary: LocalizedText(tr: 'Akşam', en: 'Evening'),
      secondaryLabel: LocalizedText(tr: 'NEDEN', en: 'WHY'),
      secondary: LocalizedText(tr: 'Çünkü', en: 'Because it helps'),
    );

void main() {
  test('format sizes are exact', () {
    expect(ShareFormat.post.size, const Size(1080, 1350));
    expect(ShareFormat.story.size, const Size(1080, 1920));
    expect(ShareFormat.square.size, const Size(1080, 1080));
  });

  for (final format in ShareFormat.values) {
    testWidgets('ShareCard renders $format without overflow', (tester) async {
      tester.view.physicalSize = format.size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: FittedBox(
            child: SizedBox.fromSize(
              size: format.size,
              child: ShareCard(tip: _tip(), lang: 'en', format: format),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Sleep title'), findsOneWidget);
      expect(find.textContaining('Evening'), findsOneWidget);
      expect(find.textContaining('Because it helps'), findsOneWidget);
    });
  }
}
```

> If the `Tip` constructor signature differs from the fields above, adjust the
> `_tip()` factory to match `lib/data/models/tip.dart` — the fields shown mirror
> `share_card.dart`'s usage (`tip.title/primaryLabel/primary/secondaryLabel/secondary/emoji/pillar/category`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/share_card_test.dart`
Expected: FAIL — `ShareFormat` undefined / `ShareCard` has no `format` param.

- [ ] **Step 3: Add the enum + per-format layout numbers**

In `lib/widgets/share_card.dart`, add above the `ShareCard` class:

```dart
/// Aspect ratios offered when sharing a tip as an image.
enum ShareFormat {
  post(Size(1080, 1350)),
  story(Size(1080, 1920)),
  square(Size(1080, 1080));

  const ShareFormat(this.size);
  final Size size;
}

/// Per-format layout tuning so one card composition serves all three ratios.
class _CardMetrics {
  const _CardMetrics({
    required this.padding,
    required this.arcWidth,
    required this.emojiSize,
    required this.titleScale,
    required this.gapAfterTitle,
    required this.gapBetweenBlocks,
    required this.footerFlex,
  });

  final EdgeInsets padding;
  final double arcWidth;
  final double emojiSize;
  final double titleScale; // multiplied into the base title size
  final double gapAfterTitle;
  final double gapBetweenBlocks;
  final int footerFlex;

  static _CardMetrics of(ShareFormat f) {
    switch (f) {
      case ShareFormat.post:
        return const _CardMetrics(
          padding: EdgeInsets.fromLTRB(96, 96, 96, 80),
          arcWidth: 280,
          emojiSize: 132,
          titleScale: 1.0,
          gapAfterTitle: 56,
          gapBetweenBlocks: 36,
          footerFlex: 2,
        );
      case ShareFormat.story:
        return const _CardMetrics(
          padding: EdgeInsets.fromLTRB(112, 260, 112, 240),
          arcWidth: 340,
          emojiSize: 148,
          titleScale: 1.0,
          gapAfterTitle: 64,
          gapBetweenBlocks: 44,
          footerFlex: 2,
        );
      case ShareFormat.square:
        return const _CardMetrics(
          padding: EdgeInsets.fromLTRB(80, 72, 80, 64),
          arcWidth: 200,
          emojiSize: 96,
          titleScale: 0.72,
          gapAfterTitle: 32,
          gapBetweenBlocks: 24,
          footerFlex: 1,
        );
    }
  }
}
```

- [ ] **Step 4: Make `ShareCard` consume the format**

Replace the `ShareCard` field/constructor block and `build`'s size/padding/spacing usages so they read from `_CardMetrics`. Concretely:

```dart
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.tip,
    required this.lang,
    this.format = ShareFormat.post,
  });

  final Tip tip;
  final String lang;
  final ShareFormat format;

  @override
  Widget build(BuildContext context) {
    final category = categoryById(tip.category);
    final isWellness = tip.pillar == ContentPillar.wellness;
    final m = _CardMetrics.of(format);
    final size = format.size;

    return Container(
      width: size.width,
      height: size.height,
      color: AppColors.ink,
      padding: m.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: TimeArc(
              position: arcPositionForTip(tip),
              width: m.arcWidth,
              dotColor: AppColors.saffron,
              arcColor: AppColors.paper.withValues(alpha: 0.25),
            ),
          ),
          const Spacer(),
          Text(tip.emoji, style: TextStyle(fontSize: m.emojiSize)),
          const SizedBox(height: 24),
          Text(
            tip.title.of(lang),
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontWeight: FontWeight.w600,
              fontSize: (isWellness ? 76 : 58) * m.titleScale,
              height: 1.1,
              color: AppColors.paper,
            ),
          ),
          SizedBox(height: m.gapAfterTitle),
          _block(tip.primaryLabel.of(lang), tip.primary.of(lang),
              44 * m.titleScale.clamp(0.85, 1.0)),
          SizedBox(height: m.gapBetweenBlocks),
          _block(tip.secondaryLabel.of(lang), tip.secondary.of(lang),
              38 * m.titleScale.clamp(0.85, 1.0)),
          Spacer(flex: m.footerFlex),
          Row(
            children: [
              Text(category?.emoji ?? '', style: const TextStyle(fontSize: 36)),
              const Spacer(),
              Text(
                'Vakti',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontWeight: FontWeight.w600,
                  fontSize: 40,
                  color: AppColors.paper.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
```

Leave the existing `_block(...)` helper method unchanged (it already takes a `valueSize`).

- [ ] **Step 5: Run tests + analyze**

Run: `flutter test test/share_card_test.dart`
Expected: PASS (1 size test + 3 render tests).
Run: `dart analyze lib test`
Expected: clean. If `share_service.dart` references the removed `ShareCard.size`, it is fixed in Task 5 — analyze may flag it until then; proceed to Task 5 before final commit if so. To keep this task self-contained, do Step 6 which patches the one call site.

- [ ] **Step 6: Fix the one existing caller reference**

`lib/services/share_service.dart` currently passes `targetSize: ShareCard.size`. Change it to `targetSize: ShareCard( ... ).format.size` is awkward — instead update the service call in Task 5. For THIS task's analyze to pass, temporarily change `share_service.dart` line to `targetSize: ShareFormat.post.size` and `ShareCard(tip: tip, lang: lang)` (default format). This keeps behavior identical (4:5) and compiles.

```dart
    final bytes = await controller.captureFromWidget(
      ShareCard(tip: tip, lang: lang),
      context: context,
      pixelRatio: 1,
      targetSize: ShareFormat.post.size,
    );
```

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/share_card.dart lib/services/share_service.dart test/share_card_test.dart
git commit -m "feat(share): ShareFormat enum + format-aware ShareCard"
```

---

### Task 5: l10n + bottom-sheet format picker in ShareService

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb` (+ `flutter gen-l10n`)
- Modify: `lib/services/share_service.dart`

**Interfaces:**
- Consumes: `ShareFormat` (Task 4), `ShareCard(format:)` (Task 4).
- Produces: `l.shareFormatTitle/shareFormatPost/shareFormatStory/shareFormatSquare`; `ShareService.shareTip` now opens a picker.

- [ ] **Step 1: Add EN + TR strings**

`app_en.arb` (before `tipsLoaded`):

```json
  "shareFormatTitle": "Share as",
  "shareFormatPost": "Post",
  "shareFormatStory": "Story",
  "shareFormatSquare": "Square",

```

`app_tr.arb` (before final `tipsLoaded` line):

```json
  "shareFormatTitle": "Farklı paylaş",
  "shareFormatPost": "Gönderi",
  "shareFormatStory": "Story",
  "shareFormatSquare": "Kare",
```

Run: `flutter gen-l10n` — expect clean.

- [ ] **Step 2: Rewrite `share_service.dart` with the picker**

Replace the file body's `shareTip` with a sheet + render helper:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../app/theme/app_colors.dart';
import '../data/models/tip.dart';
import '../l10n/app_localizations.dart';
import '../widgets/share_card.dart';

/// Renders a tip into a branded PNG and opens the system share sheet (§9.2).
/// The user first picks an aspect ratio (Post 4:5 / Story 9:16 / Square 1:1).
class ShareService {
  const ShareService();

  Future<void> shareTip(BuildContext context, Tip tip, String lang) async {
    final format = await _pickFormat(context);
    if (format == null || !context.mounted) return;
    await _renderAndShare(context, tip, lang, format);
  }

  Future<ShareFormat?> _pickFormat(BuildContext context) {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<ShareFormat>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l.shareFormatTitle,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            _FormatTile(
              format: ShareFormat.post,
              label: l.shareFormatPost,
              ratio: 4 / 5,
            ),
            _FormatTile(
              format: ShareFormat.story,
              label: l.shareFormatStory,
              ratio: 9 / 16,
            ),
            _FormatTile(
              format: ShareFormat.square,
              label: l.shareFormatSquare,
              ratio: 1,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _renderAndShare(
    BuildContext context,
    Tip tip,
    String lang,
    ShareFormat format,
  ) async {
    final controller = ScreenshotController();
    final bytes = await controller.captureFromWidget(
      ShareCard(tip: tip, lang: lang, format: format),
      context: context,
      pixelRatio: 1,
      targetSize: format.size,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vakti_${tip.id}_${format.name}.png');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Vakti'),
    );
  }
}

/// A single format row: a mini preview rect in the correct ratio + label.
class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.format,
    required this.label,
    required this.ratio,
  });

  final ShareFormat format;
  final String label;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(format),
      leading: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AspectRatio(
            aspectRatio: ratio,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.saffron, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
      title: Text(label),
    );
  }
}

final shareService = ShareService();
```

- [ ] **Step 3: Analyze**

Run: `dart analyze lib test`
Expected: clean.

- [ ] **Step 4: Full test suite**

Run: `flutter test`
Expected: all pass (existing 16 + new search + share tests). No test drives the
share sheet (it needs a real `BuildContext`/navigator), so nothing regresses.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_tr.arb lib/l10n/app_localizations*.dart lib/services/share_service.dart
git commit -m "feat(share): bottom-sheet format picker (4:5 / 9:16 / 1:1)"
```

---

### Task 6: Visual verification of share layouts (REQUIRED)

**Files:**
- Create (throwaway): `test/share_render_harness_test.dart`
- No production changes unless a layout reads badly (then tune Task 4 `_CardMetrics`).

**Why:** CLAUDE.md mandates the rendered PNGs be eyeballed, not assumed. This
task captures each format to a real PNG the reviewer can open, and iterates the
per-format numbers until all three read well.

- [ ] **Step 1: Write a harness test that writes PNGs to scratchpad**

Create `test/share_render_harness_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/content_pillar.dart';
import 'package:vakti/data/models/localized_text.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/widgets/share_card.dart';

const _outDir =
    '/private/tmp/claude-501/-Volumes-ProjectVault-VAKT-/00f7a0e2-701f-40e9-a2cd-aa2b4c9a2ad4/scratchpad';

Tip _tip() => const Tip(
      id: 't1',
      pillar: ContentPillar.communication,
      category: 'boundaries',
      emoji: '🌙',
      title: LocalizedText(
          tr: '"Şimdi olmaz" demek reddetmek değildir.',
          en: '"Not now" is not the same as "no".'),
      primaryLabel: LocalizedText(tr: 'NE ZAMAN', en: 'WHEN'),
      primary: LocalizedText(
          tr: 'Çocuğun ısrar ettiğinde.',
          en: 'When your child keeps pushing for something.'),
      secondaryLabel: LocalizedText(tr: 'NEDEN', en: 'WHY'),
      secondary: LocalizedText(
          tr: 'Sınır koymak güven verir.',
          en: 'A calm limit gives a child a sense of safety.'),
    );

void main() {
  testWidgets('render all share formats to PNG', (tester) async {
    Directory(_outDir).createSync(recursive: true);
    for (final format in ShareFormat.values) {
      final key = GlobalKey();
      tester.view.physicalSize = format.size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: const MediaQueryData(),
              child: SizedBox.fromSize(
                size: format.size,
                child: ShareCard(tip: _tip(), lang: 'en', format: format),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      File('$_outDir/share_${format.name}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
```

- [ ] **Step 2: Run the harness**

Run: `flutter test test/share_render_harness_test.dart`
Expected: PASS; three files written:
`share_post.png`, `share_story.png`, `share_square.png` in the scratchpad.

- [ ] **Step 3: Eyeball each PNG**

Read each PNG (image Read tool). Confirm per format:
- No text clipped at edges; title + WHEN + WHY all visible.
- Story: content sits in the safe middle band (generous top/bottom).
- Square: everything fits, nothing cramped/overlapping.
- Arc, category emoji, and "Vakti" watermark present.

- [ ] **Step 4: Tune if needed**

If any format reads badly, adjust the matching `_CardMetrics.of(...)` numbers in
`lib/widgets/share_card.dart` (padding / arcWidth / emojiSize / titleScale /
gaps), re-run Step 2, re-check. Repeat until all three read well.

- [ ] **Step 5: Delete the harness + commit tuning**

The harness writes to an absolute scratchpad path and is not a real test — remove
it so it does not run in CI.

```bash
rm test/share_render_harness_test.dart
git add lib/widgets/share_card.dart
git commit -m "fix(share): tune per-format layout after visual check" || echo "no tuning needed"
```

- [ ] **Step 6: Final full suite + analyze**

Run: `flutter test`
Expected: all pass.
Run: `dart analyze lib test`
Expected: clean.

---

## Notes for the implementer
- Do Tasks in order; Task 3 depends on 1+2, Task 5 depends on 4.
- Never run `flutter analyze` — Turkish-İ path crashes it. Use `dart analyze lib test`.
- If the `Tip` constructor in `lib/data/models/tip.dart` differs from the test
  factories, adjust the factory args to match — the field NAMES used
  (`title/primaryLabel/primary/secondaryLabel/secondary/emoji/pillar/category/id`)
  are taken from `share_card.dart` and are stable.
- After all tasks: update `CLAUDE.md` ideas backlog — mark "Search history /
  popular tags" and "Story (9:16) + square (1:1) share formats" as shipped.
