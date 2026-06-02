# Phase 10 Log: Transcription Reliability v0

Date: 2026-06-02

## Goal

Make iPhone-side AI processing recoverable. A watch recording should keep its
audio file, processing state, failure reason, attempt count, and retry path even
if the AI request fails or the iPhone app restarts.

## Why This Phase

The true-device loop now works:

1. Apple Watch records audio.
2. iPhone receives audio.
3. The configured AI provider produces a structured note.
4. The iPhone app exports a short note to Obsidian.

The next product risk is not adding more destinations. It is making sure
recordings and processing state are never silently lost.

## What Changed

- Extended `InboxRecording.Status` with durable processing states:
  - `readyForTranscription`
  - `transcribing`
  - `draftReady`
  - `transcriptionFailed`
- Added per-recording transcription metadata:
  - error message
  - attempt count
  - last attempt timestamp
- Added `PhoneInboxStore.updateTranscriptionState(...)`.
- Added `PhoneInboxStore.markInterruptedTranscriptionsFailed(...)`.
- Kept legacy manifest compatibility so installed data without the new fields
  still loads with safe defaults.
- Updated the iPhone processing flow:
  - marks recordings `transcribing` before the provider call,
  - marks recordings `draftReady` after saving a draft,
  - marks recordings `transcriptionFailed` on provider/config/network failure.
- On app startup, interrupted `transcribing` records are converted into failed,
  retryable records.
- Updated each iPhone inbox row to show draft status, failure message, attempt
  count, and retry semantics.

## Out Of Scope

- Long-audio chunking and merge quality.
- Background execution guarantees for very long uploads.
- File-based Obsidian export for large Markdown.
- Automatic retry scheduling.

Those are important, but this phase only makes the current manual processing
flow durable and inspectable.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Result:

- 7 tests passed.
- New tests cover persisted transcription transitions, legacy manifest
  compatibility, and interrupted transcription recovery.

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Result:

- 12 tests passed.

Passed:

```sh
swift test --package-path WatchMemo/packages/NoteDeliveryCore
```

Result:

- 4 tests passed.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WatchMemoPhase10ReliabilitySimDerivedData \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoPhase10ReliabilityWatchDerivedData \
  build
```

## True-Device Validation

Passed on 2026-06-02:

1. Built the Phase 10 app for the real iPhone destination.
2. Installed and launched the updated iPhone app.
3. Installed and launched the updated Apple Watch app.
4. User confirmed the normal watch recording to iPhone to AI draft flow still
   works.
5. User confirmed failure/retry behavior works.
6. User confirmed app restart recovery behavior works.

## Next Risks

- Determine MiMo's practical maximum audio duration and payload size.
- Add long-recording segmentation only after the state machine can preserve
  every intermediate result.
- Add file-based note export before relying on Obsidian for long transcripts.
