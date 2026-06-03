# Phase 20: Stitch AI Result Detail

Date: 2026-06-03

## Goal

Bring the expanded iPhone memo card closer to the Stitch AI result screen while
keeping the implementation incremental and preserving the existing app flow.

## Implemented

- Added a detail-style expanded card panel for recordings that already have an
  AI draft.
- Added a static waveform playback panel with real play/stop wiring.
- Added structured AI sections:
  - tags,
  - summary,
  - key conclusions,
  - transcript/body,
  - action items.
- Extracted key conclusions from the existing `## 关键结论` marker embedded in
  `StructuredTranscriptNote.body`.
- Added an Obsidian preview card that shows the expected folder/file path using
  current Obsidian settings and the recording date.
- Added a detail action bar with real Copy Markdown and Export to Obsidian
  actions.
- Kept the card-level action bar for collapsed cards and pending/failed states.

## Deferred

- Real audio waveform rendering.
- Dedicated detail navigation route.
- Editable transcript text.
- Full-width fixed bottom action bar outside the card.
- True visual screenshot validation.

## Validation

- Initial iOS Simulator build failed because of an unterminated string literal
  in the safe filename character set.
- After fixing the escaping, this command passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase20DerivedData build
```

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
- `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase20FinalDerivedData build`
  - Result: passed.

Optional true-device install remains pending.
