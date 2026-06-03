# Phase 19: Stitch Inbox UI

Date: 2026-06-03

## Goal

Move the iPhone inbox toward the Google Stitch design while preserving the
working Watch-to-iPhone-to-AI-to-Obsidian loop.

## Implemented

- Replaced the iPhone `List` inbox with a dark custom `ScrollView` shell.
- Added a Stitch-like top app bar with `WatchMemo`, Provider settings, Obsidian
  settings, debug sample import, and a static account placeholder.
- Added a status strip with one-tap copy.
- Added `All / Pending / Done / Failed` recording filters.
- Added card-based recording rows with:
  - best available title,
  - timestamp,
  - duration,
  - audio size,
  - source,
  - status dot,
  - processing / failed / done state,
  - diagnostics,
  - playback,
  - AI retry/refresh,
  - Markdown copy,
  - Obsidian export.
- Added expanded structured note preview sections for summary, body, action
  items, and tags.
- Added static bottom navigation placeholders for Inbox, Archive, and Settings.
- Added a floating iPhone record placeholder that explains Watch recording is
  still the active path.

## Deferred

- True waveform rendering.
- Account flow.
- Archive flow.
- iPhone-native recording.
- Dedicated AI result detail screen.
- Watch UI refresh.

## Validation

- `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoStitchInboxDerivedData build`
  - Result: passed.

Package regression and true-device validation should follow before calling this
phase fully complete on devices.

## Final Local Validation

- `swift test --package-path WatchMemo/packages/TranscriptPipelineCore`
  - Result: passed, 16 tests.
- `swift test --package-path WatchMemo/packages/PhoneInboxCore`
  - Result: passed, 7 tests.
- `swift test --package-path WatchMemo/packages/NoteDeliveryCore`
  - Result: passed, 4 tests.
- `swift test --package-path WatchMemo/packages/LongAudioProcessingCore`
  - Result: passed, 4 tests.
- `swift test --package-path WatchMemo/packages/WatchDeliveryCore`
  - Result: passed, 2 tests.
- `swift test --package-path WatchMemo/packages/WatchMemoMessageCore`
  - Result: passed, 3 tests.
- `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoStitchInboxDerivedDataFinal build`
  - Result: passed.

No simulator was already booted during validation, so visual inspection still
needs a simulator launch or true-device install.
