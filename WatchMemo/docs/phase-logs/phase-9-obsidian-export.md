# Phase 9 Log: Obsidian Export v0

Date: 2026-06-02

## Goal

Send a generated WatchMemo note into Obsidian with the smallest reliable user
workflow before revisiting agent handoff or multi-destination export.

## Direction Change

The agent handoff idea is useful long term, but it is too broad for the current
stage. The immediate product goal is narrower:

1. Record reliably from Apple Watch.
2. Receive and persist audio on iPhone.
3. Generate accurate, faithful AI text.
4. Export the resulting Markdown note to Obsidian.

## What Changed

- Added `NoteDeliveryCore`.
- Added `ObsidianExportURLBuilder` for `obsidian://new` export URLs.
- Added long-content protection: content above the URI threshold is refused
  instead of risking silent truncation.
- Added Obsidian settings in the iPhone app:
  - vault name
  - folder path
  - open after export
- Added `Export Obsidian` on generated note rows.
- If a note is too long for URI export, the app copies Markdown to the
  clipboard and reports the limitation instead of discarding content.

## Guardrail For Long Recordings

Obsidian URI export is a first validation path, not the final long-recording
delivery mechanism. Long recordings need:

- local audio persistence,
- local draft persistence,
- chunked or model-supported long-audio processing,
- file-based or plugin/API-based export for large Markdown notes.

This phase intentionally avoids pretending that URL export is enough for long
meeting transcripts.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/NoteDeliveryCore
```

Result:

- 4 tests passed.
- Tests cover Obsidian URL creation, optional vault/folder handling, empty
  Markdown rejection, and long-content refusal.

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Result:

- 12 tests passed.

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Result:

- 4 tests passed.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WatchMemoPhase9ObsidianSimDerivedData \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoPhase9ObsidianWatchDerivedData \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoPhase9ObsidianIOSDerivedData \
  build
```

## True-Device Validation

Passed on 2026-06-02:

1. Installed and launched the updated iPhone app.
2. Installed and launched the updated Apple Watch app.
3. Confirmed a real Apple Watch recording reached the iPhone.
4. Confirmed the configured AI provider generated note text.
5. Tapped `Export Obsidian`.
6. User confirmed the note opened/created successfully in iPhone Obsidian.

Still pending for a later reliability phase:

- Test a deliberately long note to verify fallback behavior copies Markdown
  instead of attempting an unsafe URL export.
- Replace URI export with file-based or plugin/API-based export for long notes.
