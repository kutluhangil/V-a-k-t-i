# "Today's Card" Hero — Design

**Date:** 2026-06-30
**Status:** Approved
**Feature:** Pin the deterministic daily tip to the top of the feed, marked with a
"Today's Card" badge, so opening the app always surfaces a fresh reason to return.

## Goal

Give the app a daily anchor. `dailyTipProvider` already picks one deterministic tip
per date (shared with the widget + notification). Surface it as the first card in the
feed with a badge, so the user lands on "today's" card every launch.

Offline-first, no backend, no analytics — consistent with the rest of the app.

## Non-goals (YAGNI)

- No date text on the badge (label only).
- No separate launch/welcome screen or sheet.
- No once-per-day gating — the card is always pinned first; it changes when the date
  changes (deterministic), nothing to track.

## Data / ordering (`lib/features/feed/feed_providers.dart`)

Add a pure, unit-testable helper:

```dart
List<Tip> pinFirst(List<Tip> tips, Tip? daily)
```

- If `daily == null` → return `tips` unchanged.
- Otherwise → return `[daily, ...tips.where((t) => t.id != daily.id)]` (daily moved to
  front, any duplicate removed).

`feedTipsProvider` builds the existing pillar + interests ordering first, then returns
`pinFirst(result, ref.watch(dailyTipProvider))`. Result: today's card is always first
across every filter, never duplicated. Under a pillar filter whose set excludes the
daily card, it is still prepended (per the agreed "always pin" decision).

## Visual (`lib/features/feed/feed_screen.dart`)

The feed already wraps each card in a `Stack` (for the floating `TipActions`). For the
item at `i == 0`, add one more overlay: a saffron pill badge reading the localized
"Today's Card" string, positioned top-left over the card's hero area. `TipCard` itself
is not modified.

Badge style mirrors the existing streak chip: `r999`, `AppColors.saffron` at ~14%
alpha background, `AppColors.saffronDeep` text, `AppTypography.labelCaps`,
`fontWeight: w700`.

## l10n (`lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb`)

- `feedTodayBadge` → EN "Today's Card", TR "Günün Kartı".

## Testing (`test/`)

- `pinFirst` pure tests: daily moved to front; existing duplicate removed; `null`
  daily leaves the list unchanged; daily not in list still gets prepended.
- Light widget test (mirroring `app_smoke_test` setup — `initInMemory`, reset
  `appRouter`, `onboardingDone = true`): feed renders the "Today's Card" badge.

## Files touched

- `lib/features/feed/feed_providers.dart` — `pinFirst` helper + `feedTipsProvider`.
- `lib/features/feed/feed_screen.dart` — badge overlay on the first card.
- `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb` — `feedTodayBadge`.
- `test/feed_today_test.dart` — new (`pinFirst` + badge).
