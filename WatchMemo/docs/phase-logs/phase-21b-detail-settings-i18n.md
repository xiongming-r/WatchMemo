# Phase 21B: Detail Page, Settings, and i18n

Date: 2026-06-04

## Goal

Refine the iPhone companion app after the full-screen compatibility fix:

- move AI output from inline card expansion to a dedicated memo detail page,
- add app-level English / Simplified Chinese switching,
- consolidate provider and Obsidian configuration into a more polished Settings
  surface,
- keep the watch recording -> iPhone receive -> AI note -> Obsidian export loop
  intact.

## Implemented

- Added `AppSettingsStore` with persisted app language selection.
- Added `AppSettingsView` as a dark, card-based Settings screen.
- Settings now includes:
  - app language,
  - AI provider mode,
  - endpoint / model / API key,
  - Obsidian vault / folder / open-after-export.
- Injected app settings through `WatchMemoApp`.
- Changed Inbox behavior:
  - recording cards are now compact entry cards,
  - tapping a card navigates to a dedicated memo detail page,
  - cards show AI summary previews when available,
  - details no longer expand inline inside the list.
- Added `MemoDetailScreen` for:
  - title,
  - metadata,
  - playback panel,
  - AI summary / conclusions / transcript / action items,
  - Obsidian preview,
  - copy Markdown and export actions.
- Localized major long-lived UI labels and controls for English and Simplified
  Chinese. Runtime status strings from lower-level processing are still partly
  English and can be normalized in a later i18n hardening pass.

## Validation

- Initial simulator build caught two SwiftUI integration issues:
  - navigation selection needed `Hashable`,
  - filter title lookup needed main-actor isolation.
- After fixes, iOS Simulator build passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase21B2DerivedData build
```

- After true-device feedback, fixed duplicated audio playback panels on memo
  detail pages. The root cause was that both `MemoDetailScreen` and
  `AIResultDetailView` rendered `AudioDetailPanel`.
- Added playback progress state to `AudioPlaybackController` and displayed it
  in the single detail audio panel.
- Playback fix validation passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPlaybackFixSimDerivedData build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoPlaybackFixDeviceDerivedData build
xcrun devicectl device install app --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 /private/tmp/WatchMemoPlaybackFixDeviceDerivedData/Build/Products/Debug-iphoneos/WatchMemo.app
xcrun devicectl device process launch --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 com.watchmemo.app
```

## Notes

- `ProviderSettingsView` and `ObsidianSettingsView` are intentionally retained
  for now as fallback implementation pieces, but the active user path is the
  unified Settings screen.
- The i18n implementation is app-level and user-selectable rather than relying
  on system locale. This matches the requirement to switch language inside
  Settings.
