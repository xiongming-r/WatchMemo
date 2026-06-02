# Phase 11 Log: Long Recording Diagnostics v0

Date: 2026-06-02

## Goal

Prepare for long-recording work by measuring the two most important local
signals for each recording:

- audio file size,
- AI processing duration.

## Why This Phase

Before implementing chunking or long-running background flows, WatchMemo needs
to know which limit is being hit:

- watch recording duration,
- WatchConnectivity delivery,
- iPhone storage,
- API payload size,
- model audio-duration limit,
- Obsidian export size.

This phase adds the first measurement layer without changing the successful
recording-to-note flow.

## What Changed

- Persist `audioByteCount` for every imported iPhone inbox recording.
- Persist `lastTranscriptionDurationSeconds` after an AI attempt succeeds or
  fails.
- Display file size and AI timing in the iPhone inbox row.
- Keep old recording manifests compatible.

## Out Of Scope

- Audio chunking.
- Automatic long-recording retry.
- Background execution guarantees.
- File-based Obsidian export.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Result:

- 7 tests passed.
- Tests cover imported audio byte size, AI attempt duration, legacy defaults,
  and the existing retryable transcription state machine.

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
  -derivedDataPath /private/tmp/WatchMemoPhase11DiagnosticsSimDerivedData \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoPhase11DiagnosticsWatchDerivedData \
  build
```

## Next Real-Device Experiment

After installation, record test clips at increasing lengths, for example:

- 30 seconds,
- 2 minutes,
- 5 minutes,
- 10 minutes.

For each clip, record whether WatchMemo receives it, whether AI processing
succeeds, the displayed audio size, the displayed AI time, and any provider
error.
