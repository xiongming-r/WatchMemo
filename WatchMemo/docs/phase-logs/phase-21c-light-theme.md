# Phase 21C: Light Theme

Date: 2026-06-04

## Goal

Add a user-selectable light appearance for the iPhone companion app, matching
the direction of the `stitch_watchmemo_ai_voice_link_light` reference while
preserving the existing dark UI.

## Implemented

- Added `AppThemeMode` with persisted `dark` and `light` options.
- Kept `dark` as the default so the currently validated UI does not change
  unexpectedly after install.
- Added an Appearance section to the unified Settings page.
- Bound the app root to `preferredColorScheme(...)`, so changing the setting
  immediately switches the active SwiftUI color scheme.
- Converted the shared `Color.wm...` tokens into dynamic UIKit-backed colors.
- Light theme token mapping follows the Stitch light reference:
  - background: `#faf9fe`
  - card: `#ffffff`
  - elevated surface: `#f4f3f8`
  - divider / outline: `#c1c6d7`
  - primary text: `#1a1b1f`
  - secondary text: `#414755`
  - primary blue: `#0058bc`
  - active blue: `#0070eb`
  - success green: `#006b27`
  - record / warning red: `#bc000a`
  - error red: `#ba1a1a`

## Decisions Made

- Decision: implement manual app-level theme switching instead of only following
  the iOS system appearance.
  Reason: the current UI work is being validated against Google Stitch exports,
  and explicit switching makes real-device comparison easier.
- Decision: keep the existing `Color.wm...` call sites and make the tokens
  dynamic.
  Reason: this minimizes layout churn and keeps Inbox, Detail, and Settings
  visually consistent.

## Risks Found

- Risk: some SwiftUI materials, such as `.ultraThinMaterial`, are system-driven
  and may need extra tuning after real-device light-mode review.
  Mitigation: keep this pass focused on theme tokens first; adjust individual
  chrome elements only after screenshots show a concrete mismatch.
- Risk: the current iPhone app has no dedicated UI test target for appearance
  switching.
  Mitigation: validate with command-line builds now and real-device visual
  testing next.

## Validation

- iOS Simulator build passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase21CLightThemeSimDerivedData build
```

- Concrete real-iPhone build passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoPhase21CLightThemeDeviceDerivedData build
```

- The updated app installed and launched on the real iPhone:

```sh
xcrun devicectl device install app --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 /private/tmp/WatchMemoPhase21CLightThemeDeviceDerivedData/Build/Products/Debug-iphoneos/WatchMemo.app
xcrun devicectl device process launch --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 com.watchmemo.app
```

- Pending:
  - User visual check of Settings -> Appearance -> Light on the real iPhone.

## Next Phase Notes

- After true-device validation, compare light Inbox, Detail, and Settings
  screens with the Stitch light screenshots and tune spacing / card borders /
  navigation chrome as needed.
