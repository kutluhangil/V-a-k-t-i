# Streak Calendar + Milestones — Design

**Date:** 2026-06-30
**Status:** Approved
**Feature:** Dedicated streak screen with a 90-day activity grid and milestone
badges, plus a one-time full-screen celebration when a milestone is crossed.

## Goal

Make the daily streak (günlük seri) visible and rewarding to drive retention.
Today the streak exists only as a small 🔥 chip in the feed and a banner in
Settings; there is no surface that shows history or rewards continued use.

Offline-first, no backend, no analytics — consistent with the rest of the app.

## Non-goals (YAGNI)

- No back-fill of history. Day tracking starts from this release forward; the grid
  fills in over time.
- No intensity levels. A streak day is binary (app opened or not) — active days
  render as a single saffron fill, not a heat gradient.
- No new notifications tied to milestones in this iteration.

## Data layer (`services/streak_service.dart` + `data/sources/local_store.dart`)

Current state stores only `kStreakCount`, `kStreakBest`, `kStreakLastDate`. Add:

- `kStreakDays` — `List<String>` of active day keys (`yyyy-MM-dd`), capped to the
  most recent ~120 days (90-day grid + buffer). Appended in `recordToday`; older
  entries pruned on each write to keep Hive small.
- `kStreakMilestones` — `List<int>` of milestone thresholds already celebrated, so
  each milestone celebration fires at most once.

`StreakState` gains:

- `activeDays: Set<String>` — for the grid.
- `celebratedMilestones: Set<int>` — to suppress repeat celebrations.

`recordToday(now)`:

1. If today already recorded, no-op (idempotent — unchanged).
2. Compute next count via existing `nextCount` (same-day/yesterday/gap rules).
3. Add today's key to the day set; prune keys older than 120 days.
4. Persist count, best, lastDate, day set.

Pure, unit-testable helpers (no Hive):

- `StreakService.milestones` = `[3, 7, 30, 100]` (const).
- `pendingMilestone({required int current, required Set<int> celebrated})` →
  returns the highest milestone `<= current` that is not in `celebrated`, else
  `null`. Returns at most one per call; if several were crossed at once (clock
  jumps), the largest crossed-but-uncelebrated is returned and the rest are marked
  celebrated without their own celebration.

## Streak screen (`features/streak/streak_screen.dart`, route `/streak`)

Full screen, scrollable, sections top→bottom:

1. **Hero header** — large 🔥 + current count and label ("N günlük seri" / "N day
   streak"). Best-streak caption when best > current.
2. **90-day activity grid** — weeks as columns (~13 × 7 rows), each cell a rounded
   square. Active day = saffron fill; today = outlined; empty = soft border.
   Month abbreviations above the columns. Grid is read-only.
3. **Milestone row** — four badges (3 / 7 / 30 / 100). Unlocked = saffron fill +
   check + day number; locked = muted outline. Below it, progress toward the next
   unmet target ("100 güne 70 gün kaldı" / "70 days to 100").
4. **Rule footnote** — one line explaining how the streak works.

Entry points: feed 🔥 chip → `push('/streak')`; Settings streak banner →
`push('/streak')`.

## Celebration (full-screen, once per milestone)

When `recordToday` results in a non-null `pendingMilestone`, show a full-screen
celebration overlay:

- Time-arc draw-in animation + "7 günlük seri! 🔥" + milestone label + a scatter of
  the saffron accent.
- A dismiss button. On dismiss, the milestone is added to `celebratedMilestones`
  and persisted to `kStreakMilestones`.

Trigger: after `recordToday` runs on app open. A provider/listener observes the
new `pendingMilestone` and presents the overlay (route or dialog) over the current
screen, so it works regardless of which tab is active.

## l10n (`l10n/app_en.arb`, `l10n/app_tr.arb`)

New strings (TR + EN): screen title, current/best labels (reuse existing where
possible), milestone labels, next-target copy (parameterized by remaining days),
celebration text (parameterized by milestone), rule footnote, and month
abbreviations for the grid header.

## Testing (`test/`)

`StreakService` unit tests (no Hive):

- Same-day `recordToday` is idempotent (count + day set unchanged).
- Yesterday → +1; gap → reset to 1.
- Day-set pruning keeps only the last 120 days.
- `pendingMilestone` returns the correct threshold on crossing, `null` otherwise,
  and never re-fires an already-celebrated milestone.

## Files touched

- `lib/services/streak_service.dart` — extend state, day history, milestone helper.
- `lib/data/sources/local_store.dart` — new keys.
- `lib/features/streak/streak_screen.dart` — new.
- `lib/features/streak/streak_celebration.dart` (or widget) — new.
- `lib/app/router.dart` — `/streak` route + celebration presentation hook.
- `lib/features/feed/feed_screen.dart` — make 🔥 chip tappable.
- `lib/features/settings/settings_screen.dart` — make banner tappable.
- `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb` — new strings.
- `test/streak_service_test.dart` — new/extended.
