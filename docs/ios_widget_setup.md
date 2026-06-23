# iOS Home Screen Widget — one-time Xcode setup

The Dart side (`widget_service.dart`), the SwiftUI source (`ios/VaktiWidget/`),
the App Group entitlements, and the Android widget are all in place. iOS
WidgetKit requires a **Widget Extension target**, which must be added once in
Xcode (it cannot be created safely by editing `project.pbxproj` by hand).

The main app builds and runs without this step — the widget just won't appear on
the iOS home screen until the target is added.

## Steps

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.** Name it `VaktiWidget`.
   Uncheck "Include Live Activity" and "Include Configuration App Intent".
3. When Xcode creates the target, **replace** the generated
   `VaktiWidget.swift` / `Info.plist` with the ones already in
   `ios/VaktiWidget/` (this repo), or point the new target's files at them.
4. Select the **Runner** target → Signing & Capabilities → **+ Capability →
   App Groups** → add `group.com.vakti.app`. Confirm
   `ios/Runner/Runner.entitlements` is referenced (CODE_SIGN_ENTITLEMENTS).
5. Select the **VaktiWidget** target → Signing & Capabilities → **App Groups** →
   add the same `group.com.vakti.app`. Set its entitlements file to
   `ios/VaktiWidget/VaktiWidget.entitlements`.
6. Add the `home_widget` pod to the widget target if prompted, or rely on the
   shared App Group `UserDefaults` (the Swift here reads the group directly).
7. Build & run. Add the Vakti widget from the home screen gallery.

## Data contract

Flutter writes these keys via `HomeWidget.saveWidgetData` into the App Group:
`emoji`, `title`, `primary`, `secondary`. The widget reads them from
`UserDefaults(suiteName: "group.com.vakti.app")`. Tapping opens `vakti://tip`.
