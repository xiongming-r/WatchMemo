# Phase 15 Log: Adaptive Long Audio Segmentation

Date: 2026-06-03

## Goal

Let the iPhone process longer recordings without forcing every recording
through small chunks.

## Model-Informed Strategy

Current model research suggests that many audio-understanding models can accept
long audio, but practical app risk comes from request size, provider timeout,
retry cost, and long-context quality drift.

WatchMemo v0 uses this adaptive policy:

- Single-pass when duration is at most 10 minutes and audio size is at most
  5 MB.
- Segmented when duration is over 10 minutes or audio size is over 5 MB.
- Segment length: 5 minutes.
- Segment overlap: 15 seconds.

## What Changed

- Added `LongAudioProcessingCore` with tested split decision and segment plan.
- Added `TranscriptPipeline.makeDraftFromSegments(...)`, which transcribes
  segment files in order and creates one final `TranscriptDraft`.
- Updated iPhone transcript processing to:
  - keep short recordings on the existing single-pass path,
  - export temporary `.m4a` segments for long/large recordings,
  - send each segment to the existing audio-understanding provider,
  - merge segment text in order,
  - remove temporary segment files after completion.

## Important Boundary

This phase does not call the model a second time to globally rewrite merged
segment text. The v0 merge is local and ordered to reduce the risk of changing
meaning. A later phase can add an explicit text-only final merge provider if
quality testing shows it is needed.

## Out Of Scope

- Per-segment persistent progress.
- Segment-level retry from the failed segment only.
- Background continuation if the app leaves foreground.
- Parallel API requests.
- Text-only second-pass model merge.
- Watch-to-iPhone chunked transfer.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
```

Result:

- 4 tests passed.
- Tests cover single-pass policy, long-duration splitting, large-file splitting,
  and overlapped segment planning.

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Result:

- 13 tests passed.
- Tests include ordered segment transcript merging.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WatchMemoLongAudioSimDerivedData \
  build
```

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
```

Result:

- `PhoneInboxCore`: 7 tests passed.
- `NoteDeliveryCore`: 4 tests passed.
- `WatchDeliveryCore`: 2 tests passed.
- `WatchMemoMessageCore`: 3 tests passed.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoLongAudioDeviceDerivedData \
  build
```

Installed and launched:

- iPhone app `com.watchmemo.app`.
- Watch app `com.watchmemo.app.watchkitapp`.

## True-Device Test

Recommended next test:

- Record 10-15 minutes on Apple Watch.
- Confirm iPhone receives the recording.
- Tap AI processing on iPhone.
- Confirm status changes through segmenting/transcribing segments.
- Confirm one final draft is produced and can still export to Obsidian.
