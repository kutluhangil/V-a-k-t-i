# Feed Depth Transition — Design

**Date:** 2026-06-30
**Status:** Approved
**Feature:** A "depth stacking" transition on the vertical feed PageView — the
outgoing card recedes (scales down, fades, lags) while the incoming card slides up
over it. No shadows (brand rule).

## Goal

Make swiping the feed feel premium and tactile. Today the vertical `PageView` slides
cards 1:1 with the finger. Add a depth-stack effect so cards feel layered as they move.

## Non-goals (YAGNI)

- No change to the time-arc (keeps its "tip's moment of day" meaning).
- No hero-image parallax inside the card (`TipCard` is untouched).
- No transition on the horizontal pillar-filter row.
- No shadows (brand: shadowless) — depth is conveyed with scale + opacity + lag only.

## Mechanics (`lib/features/feed/feed_screen.dart`)

Attach a `PageController` to the feed `PageView` and wrap each item in an
`AnimatedBuilder` listening to it. For item `i`, compute `delta = i - page` (using
`controller.page` when `position.hasContentDimensions`, else `i - initialPage`):

- `delta == 0` → centered card, identity transform.
- `delta < 0` → card above / outgoing: it should lag (move up slower than the
  viewport) so the incoming card overlaps it, plus scale down and fade out.
- `delta > 0` → card below / incoming: identity (slides up naturally).

## Pure helper

```dart
({double scale, double opacity, double lag}) depthTransform(double delta)
```

- `delta >= 0` → `(scale: 1.0, opacity: 1.0, lag: 0.0)`.
- `delta < 0` (let `t = delta.clamp(-1.0, 0.0)`):
  - `scale: 1.0 + 0.08 * t` (1.0 → 0.92)
  - `opacity: (1.0 + 1.4 * t).clamp(0.0, 1.0)` (fades to 0 by `t ≈ -0.71`)
  - `lag: -t` (0.0 → 1.0)

Pure and unit-testable. The feed applies `lag` as
`Transform.translate(Offset(0, lag * viewportHeight * 0.65))` to pin the outgoing card
back so the incoming card stacks over it, then `Transform.scale` and `Opacity`.

Transform order in the feed: outer `Transform.translate` (lag) → `Transform.scale`
→ `Opacity` → the existing card `Stack` (`TipCard` + `TipActions` + `_TodayBadge`).
Overlays move with the card.

## Accessibility

When `MediaQuery.of(context).disableAnimations` is true, skip the transform entirely
and render the plain card (identity), so reduced-motion users get a static PageView.

## Error handling

Before the PageView has been laid out (`!position.hasContentDimensions`), `page` is
null; fall back to `delta = (i - initialPage).toDouble()` so the first frame is stable.

## Testing (`test/`)

- `depthTransform` pure tests: `delta = 0` → identity; `delta = 1` → identity;
  `delta = -1` → `scale ≈ 0.92`, `opacity == 0`, `lag == 1`; monotonic between.
- Light widget test: the feed renders the first card, and a vertical swipe settles
  without throwing (the controller wiring holds up).

## Files touched

- `lib/features/feed/feed_screen.dart` — `PageController`, per-item `AnimatedBuilder`
  transform, `depthTransform` helper.
- `test/feed_depth_test.dart` — new (`depthTransform` + swipe smoke).
