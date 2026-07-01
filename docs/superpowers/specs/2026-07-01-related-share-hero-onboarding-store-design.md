# Design — Related cards, share hero, onboarding interests, store cards

Date: 2026-07-01
Status: approved

Four independent enhancements bundled in one session. iOS-specific work is
explicitly out of scope (no Apple developer account yet).

---

## Feature A — Related cards on the detail screen

### Goal
Below the encyclopedic sections, show up to 4 other cards from the same
category so a reader can keep exploring.

### Decisions (locked)
- **Same category only**, excluding the current tip.
- **Vertical list** of `FavoriteCard`s (same style as Browse search results).
- Up to **4** cards. **Hide the whole section** when none remain.

### Implementation
- `lib/features/detail/detail_screen.dart` currently builds a `CustomScrollView`
  in `_DetailBody` (a `StatefulWidget`, no `ref`). Add a new
  `_RelatedSection` **ConsumerWidget** and insert it as a `SliverToBoxAdapter`
  after the `if (tip.detail != null) _DetailSections` sliver and before the
  bottom padding sliver.
- `_RelatedSection` watches `tipRepositoryProvider`:
  ```dart
  final repo = ref.watch(tipRepositoryProvider).asData?.value;
  final related = repo == null
      ? const <Tip>[]
      : repo.byCategory(tip.category)
          .where((t) => t.id != tip.id)
          .take(4)
          .toList(growable: false);
  if (related.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
  ```
  (If placed as a plain widget inside a SliverToBoxAdapter, return
  `SizedBox.shrink()` instead of a sliver.)
- Layout: section header `l.relatedTitle` in `AppTypography.titleL`, then a
  `Column` of `FavoriteCard(tip: t, onTap: () => context.push('/tip/${t.id}'))`
  each with `padding: EdgeInsets.only(bottom: 14)`, wrapped in the same
  horizontal padding (20) used elsewhere in the body.
- `AppColors`/`AppTypography` already imported in the file. Add
  `favorite_card.dart` and `go_router` imports as needed.

### l10n
- `relatedTitle` — EN "Related cards", TR "İlgili Kartlar".

### Tests
`test/related_cards_test.dart` (pure logic on `TipRepository`):
- Build a `TipRepository` with several tips across two categories.
- Assert the related computation (same category, excludes self, capped at 4)
  by exercising `repo.byCategory(cat).where((t) => t.id != id).take(4)`.
- Assert empty when the category has only the current tip.

---

## Feature B — Watercolor hero background in the share card

### Goal
Use the per-tip watercolor art (`assets/images/cards/<id>.webp`, all 88 present)
as the share image background for a richer, more shareable image.

### Decisions (locked)
- **Full-bleed hero background + dark scrim**, white text over it.
- Applies to **all three** `ShareFormat`s (post/story/square).
- **Fallback**: when the webp is missing, keep the current arc + ink layout.

### Implementation — `lib/widgets/share_card.dart`
- Wrap the existing `Container(color: AppColors.ink, ...)` content in a `Stack`:
  1. Bottom layer: `Image.asset('assets/images/cards/${tip.id}.webp', fit:
     BoxFit.cover, width/height: format.size)` with an `errorBuilder` that
     returns a plain `ColoredBox(color: AppColors.ink)` (the fallback ground).
  2. Scrim layer: a `DecoratedBox` with a vertical `LinearGradient` from
     `AppColors.ink.withValues(alpha: 0.35)` (top) to
     `AppColors.ink.withValues(alpha: 0.92)` (bottom) so the WHEN/WHY text at
     the bottom stays legible while the art shows through at the top.
  3. Foreground: the existing `Padding` + `Column` (arc, emoji, title, blocks,
     footer) unchanged. Keep the `TimeArc` in all cases — it reads fine over
     the scrim and does not require branching on the asset's load state (which
     isn't known synchronously at build time). The scrim guarantees text
     legibility whether or not the webp resolves.
- Text colors stay `AppColors.paper`; saffron labels unchanged.
- `_CardMetrics` (paddings/scales per format) is unchanged.

### Visual verification (required — CLAUDE.md)
Fonts and webp only render correctly on a device/sim, not in `flutter_test`.
After building, run the app on the booted simulator with the throwaway
`SHARE_GALLERY` gallery (re-add it, as in the prior session) to eyeball all
three formats with a real webp + real fonts, confirm text legibility over the
scrim, then remove the gallery. Do NOT commit the gallery.

### Tests
`test/share_card_test.dart` (extend existing): the three no-overflow render
tests still pass with the Stack/hero/scrim in place (the asset fails to load in
tests → errorBuilder ground; text still present). Assert `takeException()` is
null and title/WHEN/WHY text present, as today.

---

## Feature C — Interest selection in onboarding

### Goal
Let first-run users pick interest categories, which already bias the feed
(`feed_providers.dart` surfaces chosen categories first).

### Decisions (locked)
- Add an **optional** chip section to the existing single-scroll onboarding
  screen, **before** the footer / Start button. Skipping (selecting none) is
  allowed — Start always works.
- Reuse the existing `settingsInterests` + `settingsInterestsHint` strings.

### Implementation — `lib/features/onboarding/onboarding_screen.dart`
- Before the `_Footer` (the Start button), insert a section:
  - `Text(l.settingsInterests, ...)` heading + `Text(l.settingsInterestsHint)`.
  - A `Consumer` building a `Wrap` of `FilterChip`s over `kCategories`, mirroring
    the settings sheet: `selected: interests.contains(c.id)`,
    `onSelected: (_) => ref.read(interestsProvider.notifier).toggle(c.id)`,
    `showCheckmark: false`, label `'${c.emoji} ${c.title.of(lang)}'`.
  - `OnboardingScreen` is already a `ConsumerStatefulWidget`, so `ref` is in
    scope; import `interests_provider.dart` and `category.dart`.
- No new persistence — `interestsProvider` already writes through to Hive.
- The screen is already a `SingleChildScrollView`; the added chips scroll with
  the rest. No overflow risk.

### Tests
`test/onboarding_interests_test.dart`:
- Pump `OnboardingScreen` (ProviderScope + localized MaterialApp,
  `LocalStore.instance.initInMemory()` in setUp).
- Find a category `FilterChip`, tap it, assert `interestsProvider` now contains
  that category id.

---

## Feature D — Store screenshot generator (Android 1080×1920, TR + EN)

### Goal
Produce stylized brand promo cards for the Play Store listing — not real UI
screenshots, but designed "golden hour" marketing cards.

### Decisions (locked)
- **Stylized brand cards** (designed, not app-UI screenshots).
- **Android phone 1080×1920** only. **TR + EN** → 10 PNGs.

### Content — 5 messages (each TR + EN)
| # | TR | EN |
|---|----|----|
| 1 | Doğru bilgi, doğru vakitte | The right thing, at the right time |
| 2 | Ne zaman ve neden | When, and why |
| 3 | Sağlıklı Yaşam & İletişim | Wellness & Communication |
| 4 | Reklamsız · Çevrimdışı · Ücretsiz | Ad-free · Offline · Free |
| 5 | Seri · Koleksiyon · Favoriler | Streak · Collections · Favorites |

Each card carries a short supporting subtitle line (one localized sentence)
under the headline. Subtitles authored in the generator.

### Implementation
- `StoreCard` widget defined **inside the generator test** (not in `lib/`, so it
  never ships in the app bundle). Reuses `AppColors`, `AppTypography`, `TimeArc`.
- Design: golden-hour. Odd cards on warm `AppColors.paper` ground with ink text;
  even cards on `AppColors.ink` ground with paper text — alternating for
  variety. `TimeArc` motif near the top, saffron accent underline under the
  headline, "Vakti" wordmark near the bottom. Fraunces headline (large),
  Inter subtitle.
- Generator: `test/store_cards_gen_test.dart` renders each `(message, lang)` via
  `RepaintBoundary.toImage` inside `tester.runAsync` (the render-to-PNG pattern
  proven last session), size `Size(1080, 1920)`, `pump(Duration)` (not
  `pumpAndSettle`, since `TimeArc` animates), writing to
  `store_assets/android/store_<n>_<lang>.png`.
- Deterministic output; committed alongside the generator so the PNGs can be
  uploaded later and regenerated on demand.

### Visual verification (required)
Fonts render as tofu in `flutter_test`. So the generator's PNGs are structurally
correct but not typographically final. To eyeball with real fonts: reuse the
`SHARE_GALLERY`-style throwaway approach — a temporary gallery route showing the
`StoreCard`s — run on the simulator, screenshot, iterate the layout, then remove
the throwaway route. Final committed PNGs are regenerated by the test; note in
the report that a with-fonts pass was done on-device.

### Tests
The generator test itself is the test: it asserts 10 files are written and
no exception. Add a trivial assertion that each output file exists and is
non-empty.

---

## Out of scope
- iOS screenshots / any iOS-target work (no dev account).
- Device-frame mockups; real-UI screenshots.
- New tip content.

## Gotchas to respect
- `dart analyze lib test` (never `flutter analyze` — Turkish-İ path crash).
- Riverpod 3 `Notifier`; emit new immutable state.
- Render-to-PNG MUST run inside `tester.runAsync`; use `pump(Duration)` not
  `pumpAndSettle` (TimeArc animates forever).
- Widget tests: `LocalStore.instance.initInMemory()` in setUp.
- Communication titles are quoted sentences → substring finders in tests.
