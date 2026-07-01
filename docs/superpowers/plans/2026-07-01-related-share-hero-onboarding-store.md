# Related Cards · Share Hero · Onboarding Interests · Store Cards — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add same-category related cards to the detail screen, a watercolor-hero background to share images, an interest picker in onboarding, and a Play-Store brand-card generator.

**Architecture:** Feature A adds a `_RelatedSection` ConsumerWidget sliver to the detail screen reading `tipRepository.byCategory`. Feature B wraps `ShareCard`'s content in a Stack (hero webp + dark scrim + existing composition). Feature C inserts a reused-strings FilterChip section into the existing onboarding scroll. Feature D is a test-only `StoreCard` widget + render-to-PNG generator writing `store_assets/android/`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Riverpod 3, go_router, `screenshot`, gen-l10n ARB.

## Global Constraints

- Analyze with `dart analyze lib test` — NEVER `flutter analyze` (Turkish-İ path crash).
- Riverpod 3: `Notifier`/`NotifierProvider`; emit new immutable state.
- All user-facing strings via gen-l10n ARB (`app_en.arb` + `app_tr.arb`) then `flutter gen-l10n`; both languages.
- Render-to-PNG MUST run inside `tester.runAsync`; use `pump(Duration)` not `pumpAndSettle` (TimeArc animates forever).
- Widget tests: `LocalStore.instance.initInMemory()` in setUp.
- Communication titles are quoted sentences → substring finders in tests.
- iOS work is OUT OF SCOPE.
- Colors from `AppColors`; card r20, hero r16, pills r999. No shadows.

---

### Task 1: l10n `relatedTitle`

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb`
- Generated: `lib/l10n/app_localizations*.dart` via `flutter gen-l10n`

**Interfaces:**
- Produces: `l.relatedTitle` on `AppLocalizations`.

- [ ] **Step 1: Add EN key**

In `lib/l10n/app_en.arb`, before the `"tipsLoaded":` line add:

```json
  "relatedTitle": "Related cards",
```

- [ ] **Step 2: Add TR key**

In `lib/l10n/app_tr.arb`, before the final `"tipsLoaded":` line add:

```json
  "relatedTitle": "İlgili Kartlar",
```

- [ ] **Step 3: Regenerate**

Run: `flutter gen-l10n`
Expected: no errors; `l.relatedTitle` exists.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_tr.arb lib/l10n/app_localizations*.dart
git commit -m "i18n(detail): add relatedTitle string"
```

---

### Task 2: Related cards section on the detail screen

**Files:**
- Modify: `lib/features/detail/detail_screen.dart`
- Test: `test/related_cards_test.dart`

**Interfaces:**
- Consumes: `tipRepositoryProvider`, `TipRepository.byCategory(String)` →
  `List<Tip>`, `l.relatedTitle`, `FavoriteCard({required Tip tip, required
  VoidCallback onTap})`.
- Produces: UI only.

- [ ] **Step 1: Write the failing logic test**

Create `test/related_cards_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/content_pillar.dart';
import 'package:vakti/data/models/localized_text.dart';
import 'package:vakti/data/models/tip.dart';
import 'package:vakti/data/repositories/tip_repository.dart';

Tip _t(String id, String cat) => Tip(
      id: id,
      pillar: ContentPillar.wellness,
      category: cat,
      emoji: '🌙',
      title: LocalizedText(tr: 'b $id', en: 't $id'),
      primary: const LocalizedText(tr: 'a', en: 'a'),
      secondary: const LocalizedText(tr: 'b', en: 'b'),
      primaryLabel: const LocalizedText(tr: 'NE', en: 'WHEN'),
      secondaryLabel: const LocalizedText(tr: 'ND', en: 'WHY'),
    );

List<Tip> related(TipRepository repo, Tip tip) => repo
    .byCategory(tip.category)
    .where((t) => t.id != tip.id)
    .take(4)
    .toList(growable: false);

void main() {
  test('related: same category, excludes self, capped at 4', () {
    final tips = [
      _t('1', 'sleep'),
      _t('2', 'sleep'),
      _t('3', 'sleep'),
      _t('4', 'sleep'),
      _t('5', 'sleep'),
      _t('6', 'sleep'),
      _t('7', 'energy'),
    ];
    final repo = TipRepository(tips);
    final r = related(repo, tips.first);
    expect(r.length, 4);
    expect(r.every((t) => t.category == 'sleep'), isTrue);
    expect(r.any((t) => t.id == '1'), isFalse);
  });

  test('related: empty when category has only the current tip', () {
    final tips = [_t('1', 'sleep'), _t('2', 'energy')];
    final repo = TipRepository(tips);
    expect(related(repo, tips.first), isEmpty);
  });
}
```

> If `TipRepository`'s constructor is not `TipRepository(List<Tip>)`, open
> `lib/data/repositories/tip_repository.dart` and match its real constructor.

- [ ] **Step 2: Run test to verify it fails or passes-trivially**

Run: `flutter test test/related_cards_test.dart`
Expected: PASS (this pins the selection logic the widget will use). If it
fails to compile, fix the `TipRepository` constructor call to match the source.

- [ ] **Step 3: Add the `_RelatedSection` widget + imports**

In `lib/features/detail/detail_screen.dart` add imports near the top (after
existing imports):

```dart
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/favorite_card.dart';
```

(These are not currently imported in `detail_screen.dart`. `tip.dart`,
`tip_repository.dart`, `app_colors.dart`, `app_typography.dart` already are.)

Append this widget at the end of the file:

```dart
/// "Related cards" — up to 4 other tips in the same category. Hidden when none.
class _RelatedSection extends ConsumerWidget {
  const _RelatedSection({required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(tipRepositoryProvider).asData?.value;
    final related = repo == null
        ? const <Tip>[]
        : repo
            .byCategory(tip.category)
            .where((t) => t.id != tip.id)
            .take(4)
            .toList(growable: false);
    if (related.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.relatedTitle, style: AppTypography.titleL),
          const SizedBox(height: 16),
          for (final t in related)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FavoriteCard(
                tip: t,
                onTap: () => context.push('/tip/${t.id}'),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Insert the section into the scroll**

In `_DetailBodyState.build`'s `CustomScrollView` `slivers:`, between the
`if (tip.detail != null) SliverToBoxAdapter(child: _DetailSections(...))` and
the final `const SliverToBoxAdapter(child: SizedBox(height: 48))`, insert:

```dart
        SliverToBoxAdapter(child: _RelatedSection(tip: tip)),
```

- [ ] **Step 5: Analyze**

Run: `dart analyze lib test`
Expected: clean. Remove any duplicate import the analyzer flags.

- [ ] **Step 6: Run tests**

Run: `flutter test test/related_cards_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/detail/detail_screen.dart test/related_cards_test.dart
git commit -m "feat(detail): related cards section (same category, up to 4)"
```

---

### Task 3: Watercolor hero background + scrim in ShareCard

**Files:**
- Modify: `lib/widgets/share_card.dart`
- Test: `test/share_card_test.dart` (already exists — verify still green)

**Interfaces:**
- Consumes: `format.size`, `tip.id`, `AppColors`.
- Produces: unchanged public API (`ShareCard({tip, lang, format})`).

- [ ] **Step 1: Wrap the card body in a Stack (hero + scrim)**

In `lib/widgets/share_card.dart`, the `build` currently returns
`Container(width, height, color: AppColors.ink, padding: m.padding, child:
Column(...))`. Change it so the same-size `Container` (drop its `color`) holds a
`Stack`: hero image, scrim, then the padded Column. Replace the outer
`Container(...)` opening (keep the inner `Column` exactly as-is):

```dart
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero art background; falls back to a plain ink ground if missing.
          Image.asset(
            'assets/images/cards/${tip.id}.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: AppColors.ink),
          ),
          // Dark scrim: light at top (art shows) → heavy at bottom (text
          // stays legible).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.ink.withValues(alpha: 0.35),
                  AppColors.ink.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          Padding(
            padding: m.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... EXISTING children unchanged (arc, Spacer, emoji, title,
                // blocks, footer) ...
              ],
            ),
          ),
        ],
      ),
    );
```

Keep every child inside the `Column` exactly as it is today (arc → Spacer →
emoji → title → gap → block → gap → block → footer Spacer → footer Row).

- [ ] **Step 2: Analyze**

Run: `dart analyze lib`
Expected: clean.

- [ ] **Step 3: Run the existing share_card tests**

Run: `flutter test test/share_card_test.dart`
Expected: PASS. In tests the webp asset fails to load → `errorBuilder` ink
ground; the scrim + Column still render; `takeException()` is null and the
title/WHEN/WHY substrings are found (the existing assertions).

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/share_card.dart
git commit -m "feat(share): watercolor hero background + scrim on share card"
```

> Visual verification with a real webp + fonts happens in Task 6.

---

### Task 4: Interest picker in onboarding

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Test: `test/onboarding_interests_test.dart`

**Interfaces:**
- Consumes: `interestsProvider` + `.notifier.toggle(String)`, `kCategories`,
  `l.settingsInterests`, `l.settingsInterestsHint`.

- [ ] **Step 1: Write the failing widget test**

Create `test/onboarding_interests_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/data/models/category.dart';
import 'package:vakti/data/sources/local_store.dart';
import 'package:vakti/features/onboarding/onboarding_screen.dart';
import 'package:vakti/features/settings/interests_provider.dart';
import 'package:vakti/l10n/app_localizations.dart';

void main() {
  setUp(() => LocalStore.instance.initInMemory());

  testWidgets('tapping a category chip selects that interest', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = kCategories.first;
    final lang = 'tr';
    final chip = find.widgetWithText(
      FilterChip,
      '${first.emoji} ${first.title.of(lang)}',
    );
    await tester.scrollUntilVisible(chip, 200);
    await tester.tap(chip);
    await tester.pump();

    expect(container.read(interestsProvider).contains(first.id), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/onboarding_interests_test.dart`
Expected: FAIL — no FilterChip found.

- [ ] **Step 3: Add imports**

In `lib/features/onboarding/onboarding_screen.dart` add (if not present):

```dart
import '../../data/models/category.dart';
import '../settings/interests_provider.dart';
```

- [ ] **Step 4: Insert the interests section before the CTA**

In `build`, the CTA is preceded by `const SizedBox(height: 40), // CTA`. Just
before that `SizedBox(height: 40)` (i.e. after the second `_PillarCard`), insert:

```dart
                      const SizedBox(height: 36),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.settingsInterests,
                          style: AppTypography.titleL.copyWith(color: _text),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.settingsInterestsHint,
                          style: AppTypography.bodyM.copyWith(color: _muted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, _) {
                          final lang =
                              Localizations.localeOf(context).languageCode;
                          final selected = ref.watch(interestsProvider);
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in kCategories)
                                FilterChip(
                                  label: Text('${c.emoji} ${c.title.of(lang)}'),
                                  selected: selected.contains(c.id),
                                  showCheckmark: false,
                                  onSelected: (_) => ref
                                      .read(interestsProvider.notifier)
                                      .toggle(c.id),
                                ),
                            ],
                          );
                        },
                      ),
```

> `_text` and `_muted` are the file's existing private color constants (used
> elsewhere in this build method). If a referenced constant name differs, use
> the one already used for headings/captions in this file.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/onboarding_interests_test.dart`
Expected: PASS.

- [ ] **Step 6: Analyze**

Run: `dart analyze lib test`
Expected: clean.

- [ ] **Step 7: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart test/onboarding_interests_test.dart
git commit -m "feat(onboarding): optional interest picker before Start"
```

---

### Task 5: Store brand-card generator (Android 1080×1920, TR + EN)

**Files:**
- Create: `test/store_cards_gen_test.dart` (contains the `StoreCard` widget + generator)
- Output: `store_assets/android/store_<n>_<lang>.png` (10 files)

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `TimeArc`.
- Produces: 10 committed PNGs + a re-runnable generator.

- [ ] **Step 1: Write the generator + StoreCard**

Create `test/store_cards_gen_test.dart`:

```dart
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakti/app/theme/app_colors.dart';
import 'package:vakti/app/theme/app_typography.dart';
import 'package:vakti/widgets/time_arc.dart';

const _outDir = 'store_assets/android';
const _size = Size(1080, 1920);

class _Msg {
  const _Msg(this.headlineTr, this.headlineEn, this.subTr, this.subEn);
  final String headlineTr, headlineEn, subTr, subEn;
}

const _messages = <_Msg>[
  _Msg('Doğru bilgi, doğru vakitte', 'The right thing, at the right time',
      'Küçük, yararlı fikirler — her biri ne zaman ve neden.',
      'Small, useful ideas — each with a when and a why.'),
  _Msg('Ne zaman ve neden', 'When, and why',
      'Her kart tam olarak ne yapacağını ve nedenini söyler.',
      'Every card tells you exactly what to do, and why.'),
  _Msg('Sağlıklı Yaşam & İletişim', 'Wellness & Communication',
      'İki sakin sütun: günlük iyilik ve daha sakin anlar.',
      'Two quiet columns: everyday wellbeing and calmer moments.'),
  _Msg('Reklamsız · Çevrimdışı · Ücretsiz', 'Ad-free · Offline · Free',
      'Hesap yok, takip yok. Her şey cihazında.',
      'No account, no tracking. Everything on your device.'),
  _Msg('Seri · Koleksiyon · Favoriler', 'Streak · Collections · Favorites',
      'Alışkanlığını sürdür, sevdiklerini sakla.',
      'Keep your habit going, save the ones you love.'),
];

class StoreCard extends StatelessWidget {
  const StoreCard({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.dark,
  });

  final String headline;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.ink : AppColors.paper;
    final fg = dark ? AppColors.paper : AppColors.ink;
    return SizedBox.fromSize(
      size: _size,
      child: Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(96, 200, 96, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TimeArc(
                position: 0.5,
                width: 360,
                dotColor: AppColors.saffron,
                arcColor: fg.withValues(alpha: 0.25),
              ),
            ),
            const Spacer(),
            Text(
              headline,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
                fontSize: 96,
                height: 1.05,
                color: fg,
              ),
            ),
            const SizedBox(height: 28),
            Container(width: 120, height: 6, color: AppColors.saffron),
            const SizedBox(height: 28),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 44,
                height: 1.35,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
            const Spacer(flex: 2),
            Text(
              'Vakti',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontWeight: FontWeight.w600,
                fontSize: 52,
                color: fg.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _render(WidgetTester tester, Widget card, String path) async {
  final key = GlobalKey();
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: SizedBox.fromSize(size: _size, child: card),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('generate store cards (TR + EN)', (tester) async {
    Directory(_outDir).createSync(recursive: true);
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      final dark = i.isOdd;
      await _render(
        tester,
        StoreCard(headline: m.headlineTr, subtitle: m.subTr, dark: dark),
        '$_outDir/store_${i + 1}_tr.png',
      );
      await _render(
        tester,
        StoreCard(headline: m.headlineEn, subtitle: m.subEn, dark: dark),
        '$_outDir/store_${i + 1}_en.png',
      );
    }
    for (var i = 1; i <= _messages.length; i++) {
      for (final lang in ['tr', 'en']) {
        final f = File('$_outDir/store_${i}_$lang.png');
        expect(f.existsSync(), isTrue);
        expect(f.lengthSync(), greaterThan(0));
      }
    }
  });
}
```

- [ ] **Step 2: Run the generator**

Run: `flutter test test/store_cards_gen_test.dart`
Expected: PASS; 10 PNGs written under `store_assets/android/`.

- [ ] **Step 3: Sanity-check the PNGs exist**

Run: `ls store_assets/android/`
Expected: `store_1_tr.png … store_5_en.png` (10 files).

- [ ] **Step 4: Commit generator + outputs**

```bash
git add test/store_cards_gen_test.dart store_assets
git commit -m "feat(store): Android brand-card generator + TR/EN screenshots"
```

> Font/webp render as tofu in flutter_test — the PNGs are structurally correct
> but not typographically final. Task 6 does the with-fonts pass on-device.

---

### Task 6: Visual verification on the simulator (REQUIRED) + backlog

**Files:**
- Throwaway (not committed): a `SHARE_GALLERY`-style gallery route in
  `lib/main.dart` + a temporary gallery widget, showing (a) the share-card
  formats over a real webp and (b) the store cards — with real fonts.
- Modify (commit): `CLAUDE.md` backlog; possibly `lib/widgets/share_card.dart`
  or the store `StoreCard` metrics if tuning is needed.

**Why:** CLAUDE.md mandates rendered layouts be eyeballed with real fonts, which
only happens on a device/sim.

- [ ] **Step 1: Add a throwaway gallery**

Re-create the throwaway pattern from the prior session: a `lib/dev_gallery.dart`
that shows, in a scrollable/`Row` layout, `ShareCard(tip: <a real tip id that
has a webp>, format: ...)` for all three formats AND the five `StoreCard`s (copy
the `StoreCard` class + messages in, or expose them). Guard `main()` with
`if (const bool.fromEnvironment('DEV_GALLERY')) { runApp(const DevGallery()); return; }`
added at the very top of `main()` (before `LocalStore.instance.init()`), plus
the import.

- [ ] **Step 2: Run on the booted simulator**

Boot check: `xcrun simctl list devices booted` (boot `iPhone 17` if none).
Run: `flutter run -d <udid> --dart-define=DEV_GALLERY=true` (background), wait
for "A Dart VM Service", then
`xcrun simctl io <udid> screenshot <scratchpad>/dev_gallery.png`.

- [ ] **Step 3: Eyeball**

Read the screenshot. Confirm:
- Share hero: watercolor art visible at top, scrim darkens toward bottom, white
  title + WHEN/WHY legible in all three formats.
- Store cards: headline (Fraunces) + saffron rule + subtitle + "Vakti" read
  well on both paper and ink grounds; nothing clipped.

- [ ] **Step 4: Tune if needed**

If share text is hard to read, deepen the scrim bottom alpha (e.g. `0.92`→`0.96`)
in `share_card.dart`. If a store card overflows/looks cramped, adjust
`StoreCard` font sizes/padding in `test/store_cards_gen_test.dart` and re-run
Task 5 Step 1–2 to regenerate. Re-screenshot until good.

- [ ] **Step 5: Remove the throwaway + regenerate final PNGs**

```bash
git checkout lib/main.dart
rm -f lib/dev_gallery.dart
flutter test test/store_cards_gen_test.dart   # regenerate if StoreCard tuned
```

If store cards were tuned, re-commit the regenerated PNGs:

```bash
git add store_assets test/store_cards_gen_test.dart && git commit -m "fix(store): tune brand-card layout after visual check" || echo "no tuning"
```

If the share scrim was tuned:

```bash
git add lib/widgets/share_card.dart && git commit -m "fix(share): tune hero scrim after visual check" || echo "no tuning"
```

- [ ] **Step 6: Update backlog + final verification**

In `CLAUDE.md`, under the ideas backlog, mark shipped:
- related cards on detail,
- watercolor hero share,
- onboarding interest picker,
- store screenshot generator (Android).

Then:

```bash
dart analyze lib test   # clean
flutter test            # all pass
git add CLAUDE.md && git commit -m "docs: mark related/share-hero/onboarding/store shipped"
```

---

## Notes for the implementer
- Order matters: Task 2 needs Task 1; Task 6 needs 3 + 5.
- Never run `flutter analyze` (Turkish-İ path crash). Use `dart analyze lib test`.
- If a `Tip`/`TipRepository`/`LocalizedText` signature differs from a test
  factory, adjust the factory to match the real source (field names
  `id/pillar/category/emoji/title/primary/secondary/primaryLabel/secondaryLabel`
  are stable).
- The gallery in Task 6 is throwaway — never commit it.
