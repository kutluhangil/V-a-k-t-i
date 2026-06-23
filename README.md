# Vakti

**Doğru bilgi, doğru vakitte. / The right thing, at the right time.**

Free, ad-free, offline tip-card app for iOS + Android. Two content columns —
**Sağlıklı Yaşam (Wellness)** and **İletişim (Communication)** — in Turkish and
English, with a home screen widget. No backend, no accounts, no data collected.

## Stack

Flutter · Riverpod · go_router · Hive · home_widget · workmanager ·
flutter_local_notifications · share_plus · screenshot

## Setup

```bash
flutter pub get
flutter gen-l10n
dart run flutter_launcher_icons   # generate app icons
flutter run
```

> **Analyze note:** this repo's path contains a non-ASCII character (`İ`), which
> crashes the `flutter analyze` LSP server. Use **`dart analyze lib test`**
> instead. `flutter test` is unaffected.

## Architecture

Feature-first (see `VAKTI_BLUEPRINT.md`). Built in phases (Agents 1–9):

- **lib/app** — `app.dart`, `router.dart`, theme tokens, locale/theme controllers.
- **lib/data** — models (`tip`, `category`, `localized_text`), `AssetTipSource`,
  `TipRepository`, `FavoritesController`, `LocalStore` (Hive).
- **lib/features** — `onboarding`, `feed`, `browse`, `detail`, `favorites`,
  `settings`.
- **lib/services** — `daily_tip_service` (deterministic seed), `notification_service`,
  `widget_service`, `share_service`.
- **lib/widgets** — `TipCard`, `TimeArc`, `CategoryTile`, `PillBadge`,
  `TipActions`, `ShareCard`, `EmptyState`.

Content ships in `assets/data/tips.json` (88 bilingual cards, 8 per category).

## Home screen widget

Android widget is wired and working. iOS WidgetKit needs a one-time Xcode target
step — see `docs/ios_widget_setup.md`.

## Privacy & store

- No data collected (see `PRIVACY.md`, `ios/Runner/PrivacyInfo.xcprivacy`).
- Store listing copy (TR + EN): `docs/store_listing.md`.

## Tests

```bash
flutter test
```

Covers content/schema, daily-tip seed determinism, and widget flows
(feed + filter, browse navigation, live locale switch, favorites, onboarding).

## License

TBD.
