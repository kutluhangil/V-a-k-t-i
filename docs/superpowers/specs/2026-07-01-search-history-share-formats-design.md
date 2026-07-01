# Design — Search history + popular tags & multi-format share

Date: 2026-07-01
Status: approved

Two independent backlog features for Vakti, bundled in one work session.

---

## Feature A — Search history + popular tags

### Goal
On the Browse tab, when the search field is empty, surface the user's recent
searches and the most-searched terms as tappable chips — so repeat lookups are
one tap instead of retyping.

### Product decisions (locked)
- **Session-only, in-memory.** Nothing is written to Hive/disk. Both the recent
  list and the frequency counts live only for the app session and reset on
  restart. Keeps the app's offline / no-analytics / no-personal-data-persisted
  posture intact.
- **"Popular tags" = frequency of the user's own searches** (not a curated tag
  list — the data model has no `tag` field, only 11 categories). Top 5 by count.
- **Recent = last 5 distinct queries**, most-recent-first.

### State
New Riverpod notifier `SearchHistoryController` in
`lib/features/browse/search_history_provider.dart`:

```dart
class SearchHistory {
  final List<String> recent;      // last 5 distinct, most-recent-first
  final Map<String, int> counts;  // session frequency
}
```

- `NotifierProvider<SearchHistoryController, SearchHistory>`.
- `record(String query)`:
  - normalize: `query.trim().toLowerCase()`; ignore if empty.
  - `recent`: remove existing equal entry, insert at front, cap to 5.
  - `counts`: `counts[q] = (counts[q] ?? 0) + 1`.
  - emit a new immutable `SearchHistory` (copy lists/maps — Riverpod equality).
- `removeRecent(String query)`: drop from `recent` only (leaves `counts`).
- `clearRecent()`: empties `recent` only (leaves `counts`).
- `popular` derived getter: `counts` entries sorted by count desc, then
  alphabetical for stable ties, take 5, return keys.

### Recording triggers (meaningful signal only — NOT per keystroke)
1. Search field `onSubmitted` (keyboard "search" action).
2. Tapping a search **result** row (the query that led to opening a tip).

Both call `ref.read(searchHistoryProvider.notifier).record(currentQuery)`.

### UI — `browse_screen.dart`
When `query.trim().isEmpty`, above the category `_Section`s, render a new
`_SearchDiscovery` widget:

- **Popular** block — shown only if `popular` is non-empty. Label
  `l.popularLabel`, then a `Wrap` of chips (term text). Tap → fill field + set
  query + record is NOT re-triggered (tapping a chip just runs the search;
  recording happens on submit/result-tap as above).
- **Recent** block — shown only if `recent` is non-empty. Header row:
  `l.recentSearchesLabel` on the left, a `TextButton`(`l.clearAll`) on the
  right. Then a `Wrap` of chips; each chip has a trailing (×) that calls
  `removeRecent`.
- If both are empty (cold start), render nothing → existing category grid shows
  unchanged.

Chip styling: reuse the app's pill aesthetic (r999, divider border, surface
fill, saffron on tap). A small private `_QueryChip` widget.

Tapping a chip: `_controller.text = term; ref.read(searchQueryProvider.notifier).set(term);`

### l10n
Add to `app_en.arb` / `app_tr.arb` (+ `flutter gen-l10n`):
- `popularLabel` — EN "Popular", TR "Popüler"
- `recentSearchesLabel` — EN "Recent searches", TR "Son aramalar"
- `clearAll` — EN "Clear", TR "Temizle"

### Tests
- Unit (`test/search_history_test.dart`): record dedupes + caps recent at 5;
  counts increment; popular sorted by count desc with alphabetical tiebreak and
  capped at 5; removeRecent / clearRecent leave counts intact.

---

## Feature B — Multi-format share (4:5 / 9:16 / 1:1)

### Goal
Let the user pick the share image aspect ratio — feed Post (4:5, current),
Story (9:16), Square (1:1) — via a bottom sheet, instead of always 4:5.

### Format model
`enum ShareFormat` (in `lib/widgets/share_card.dart` or a small
`share_format.dart`):

| value  | size (px)   | ratio |
|--------|-------------|-------|
| post   | 1080×1350   | 4:5   |
| story  | 1080×1920   | 9:16  |
| square | 1080×1080   | 1:1   |

Each exposes `Size get size`.

### `ShareCard` refactor
`ShareCard({required tip, required lang, ShareFormat format = ShareFormat.post})`.

- `size` comes from `format.size` (drop the old `static const size`; expose
  `format.size` to the service).
- Layout stays the same skeleton (arc → emoji → title → WHEN block → WHY block →
  footer with category emoji + "Vakti" watermark) but spacing/type scale adapt:
  - **post** — current values unchanged (regression-safe).
  - **story** — taller canvas: larger top/bottom padding so content sits in the
    safe middle band (stories overlay UI top & bottom); arc larger; more
    vertical spacing between blocks; same font sizes as post (fits easily).
  - **square** — compact: reduce title font, shrink arc, tighten block spacing
    and paddings so WHEN + WHY both fit without overflow at 1080×1080.
- Drive per-format numbers from a small internal record/switch (paddings, arc
  width, title size, block sizes, gaps) rather than scattering `if`s.

### `ShareService`
- `shareTip(BuildContext context, Tip tip, String lang)` now shows a
  **bottom sheet** (`showModalBottomSheet`, editorial style: surface bg, r20 top
  corners) listing the 3 formats. Each row: a mini aspect-ratio preview box
  (just an outlined rect in the correct ratio + label) + localized name.
- On tap: close sheet, then `_renderAndShare(context, tip, lang, format)` which
  runs the existing screenshot→temp-file→SharePlus flow with
  `ShareCard(tip, lang, format)` and `targetSize: format.size`. Temp filename
  includes the format (`vakti_${tip.id}_${format.name}.png`).

### l10n
- `shareFormatTitle` — EN "Share as", TR "Farklı paylaş"
- `shareFormatPost` — EN "Post", TR "Gönderi"
- `shareFormatStory` — EN "Story", TR "Story"
- `shareFormatSquare` — EN "Square", TR "Kare"

### Visual verification (required by CLAUDE.md)
Layouts must be eyeballed, not assumed. After building:
1. Add a throwaway/QA render harness (or a test) that captures each
   `ShareFormat` to a PNG in the scratchpad.
2. Read each PNG and confirm: no clipping, title + both blocks visible, arc
   placement sane, watermark present, safe margins on story.
3. Iterate the per-format numbers until all three read well.

### Tests
- `test/share_card_test.dart`: for each `ShareFormat`, pump `ShareCard` at
  `format.size` inside a sized/bounded harness and assert no overflow
  (no `FlutterError` / RenderFlex overflow) and the title/WHEN/WHY text is
  present.
- Assert `ShareFormat` sizes/ratios are exact.

---

## Out of scope
- Persisting search terms across launches (explicitly rejected — session-only).
- Curated tag taxonomy / tag field in `tips.json`.
- Custom per-format artwork; the existing arc+type composition is reused.

## Gotchas to respect
- `dart analyze lib test` (NOT `flutter analyze` — Turkish-İ path crash).
- Riverpod 3 `Notifier`/`NotifierProvider`; emit new immutable state objects.
- Widget tests use `LocalStore.instance.initInMemory()`; but these features add
  no Hive writes, so no store interaction needed for the search/share unit tests.
- Communication tip titles are quoted sentences → use substring finders in
  share_card tests.
