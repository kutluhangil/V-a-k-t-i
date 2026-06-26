# CLAUDE.md — Vakti

Working notes for Claude Code. Read this first when picking the project back up.

## What Vakti is

Free, ad-free, **offline-first** Flutter app (iOS + Android), bilingual **TR + EN**.
Premium "tip cards" that answer *when* and *why*. Two content pillars:

- **wellness** (Sağlıklı Yaşam) — digestion, immunity, sleep, energy, skin, hydration
- **communication** (İletişim) — boundaries, emotions, cooperation, confidence, earlyYears (child/parent)

No backend, no login, no analytics, no ads. All content ships in
`assets/data/tips.json`. Full spec: `VAKTI_BLUEPRINT.md`.

- Android applicationId: **com.studiorosemary.vakti** (Play package; `com.vakti.app`
  was taken by another dev) · Android namespace: `com.vakti.vakti` · iOS bundle id:
  **com.vakti.app** · App Group: `group.com.vakti.app` · Dart pkg: `vakti`
- Stack: Flutter 3.44.1 / Dart 3.12.1 · Riverpod 3 · go_router · Hive · home_widget ·
  workmanager · flutter_local_notifications · share_plus · screenshot
- Fonts bundled (Fraunces display + Inter body), no runtime google_fonts.
- Design: editorial "golden hour" — ink dark bg, warm paper light bg, single saffron
  accent, signature "time arc" (zaman yayı) motif. Cards r20, buttons r14, no shadows.

## Status: MVP COMPLETE

All 9 blueprint agents / 6 phases built. **`dart analyze` clean, 16/16 tests pass.**
Verified live on iPhone 17 simulator (iOS 26.5).

| Phase | Agents | What | State |
|---|---|---|---|
| 1 | 1-3 | scaffold, theme tokens, l10n (ARB+gen-l10n), data layer, 88-card tips.json | ✅ |
| 2 | 4-5 | go_router bottom-nav shell, feed (PageView + pillar filter), browse grid | ✅ |
| 3 | 6 | detail screen, Hive favorites + heart, 4:5 PNG share | ✅ |
| 4 | 7 | home_widget; Android widget FULLY wired; iOS source + doc | ✅* |
| 5 | 8 | daily reminder (opt-in), deterministic daily tip, tap routing | ✅ |
| 6 | 9 | 3-screen onboarding, full settings, legal disclaimer | ✅ |

\* iOS widget needs one manual Xcode step — see "Open items".

## Layout (feature-first)

```
lib/
  app/        app.dart, router.dart, theme/*, controllers/ (locale, theme)
  data/       models/ (tip, category, localized_text, content_pillar)
              sources/ (asset_tip_source, local_store=Hive)
              repositories/ (tip_repository, favorites_repository)
  features/   onboarding, feed, browse, detail, favorites, settings
  services/   daily_tip_service, notification_service, widget_service, share_service, reminder_copy
  widgets/    tip_card, time_arc, category_tile, pill_badge, tip_actions, share_card, empty_state
  l10n/       app_en.arb, app_tr.arb (+ generated app_localizations*)
assets/       data/tips.json · fonts/ (Fraunces, Inter) · icon/
android/ ios/ docs/ (ios_widget_setup, store_listing) · PRIVACY.md · README.md
```

## Commands

```bash
flutter pub get
flutter gen-l10n
dart run flutter_launcher_icons
flutter test
flutter run -d <device>
# show feed without onboarding (QA): --dart-define=SKIP_ONBOARDING=true
```

## ⚠️ Gotchas (read before working)

1. **`flutter analyze` CRASHES here** — repo path has Turkish `İ`
   (`/Volumes/ProjectVault/VAKTİ`), which corrupts the analysis-server LSP rootUri
   (`FormatException at character 288`). **Use `dart analyze lib test` instead.**
   `flutter test` is unaffected.
2. **Riverpod 3** — blueprint shows v2 `StateNotifierProvider`; we use modern
   `Notifier`/`NotifierProvider`. `AsyncValue` has no `valueOrNull` → use `.asData?.value`.
   Controllers set `state` BEFORE awaiting Hive persistence (optimistic) — otherwise
   real disk I/O stalls under the test fake-async clock.
3. **Widget tests** use `LocalStore.instance.initInMemory()` (no Hive). Real Hive writes
   scheduled under fake-async never settle and deadlock teardown. setUp also resets the
   **global** `appRouter` (`appRouter.go('/feed')`) and sets `onboardingDone=true`.
4. **flutter_local_notifications v22** = named params: `initialize(settings:)`,
   `zonedSchedule(id:/scheduledDate:/notificationDetails:)`, `cancel(id:)`.
   `flutter_timezone` v5 returns `TimezoneInfo` → use `.identifier`.
5. **iOS deployment target = 14.0** (Podfile + pbxproj + post_install) — workmanager_apple
   needs ≥14. **Android** needs core-library desugaring + `desugar_jdk_libs:2.1.4`
   (local_notifications v22).
6. Communication tip titles are **quoted sentences** in JSON (rendered text includes
   literal `"`) — use substring finders in tests.

## Open items / what's next

**Required before store submission**
- [ ] **iOS widget Xcode step** — add Widget Extension target `VaktiWidget`, wire App Group
      `group.com.vakti.app` on Runner + widget, point at `ios/VaktiWidget/*`.
      See `docs/ios_widget_setup.md`. (Hand-editing pbxproj was skipped to keep the iOS
      build launchable.)
- [ ] Host `PRIVACY.md` at a public URL (both stores require it).
- [ ] Real signing config (Android release keystore; iOS team/provisioning).
- [ ] Store screenshots (TR + EN) per `docs/store_listing.md` checklist.
- [ ] Verify widget on real Android device + iOS after the Xcode step.

**Nice to have / deferred**
- [ ] Streak (günlük seri) — deferred to v1.1 per blueprint §2.
- [ ] Expand content beyond 88 cards if desired.
- [ ] Adult/partner communication content (currently child/parent only).
- [ ] in_app_review for the "Rate" action (currently a placeholder tile).
- [ ] Remove `SKIP_ONBOARDING` QA flag before release if undesired (defaults false).

**Not yet done**
- [ ] No git commit made yet — working tree has all the above uncommitted.
- [ ] CI (flutter analyze via `dart analyze` + flutter test).

## Memory

Persistent notes live in
`~/.claude/projects/-Volumes-ProjectVault-VAKT-/memory/vakti-project.md`.
