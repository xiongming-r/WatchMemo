# Phase 16 Log: Transcript Quality And Speaker Metrics

Date: 2026-06-03

## Goal

Make long-recording validation easier by improving the audio-understanding
instruction and showing compact text-quality diagnostics on the iPhone.

## What Changed

- Strengthened the OpenAI-compatible provider instruction:
  - remove fillers, meaningless pauses, repeated words, stutters, and obvious
    slips,
  - preserve the original meaning and uncertainty,
  - avoid inventing any fact that is not in the audio,
  - use `说话人 A/B/C` labels only when multiple speakers are clearly
    distinguishable.
- Added `TranscriptQualityMetrics` to persisted drafts:
  - raw character count,
  - cleaned character count,
  - compression ratio,
  - removed filler count,
  - segment count,
  - segmented-processing flag,
  - detected speaker labels,
  - estimated speaker count.
- Added lightweight speaker-label detection from model output line prefixes
  such as `说话人 A：` and `Speaker A:`.
- Updated the iPhone inbox row diagnostics to show text length compression,
  segment count, and estimated speaker count.

## Important Boundary

Speaker support is not biometric voice recognition. Phase 16 only detects
speaker labels that the model has already produced in the organized text. If
the model cannot reliably separate speakers, the prompt tells it not to force
speaker labels.

## Out Of Scope

- True speaker identity recognition.
- Per-speaker summaries.
- Per-segment retry or persistent segment progress.
- A second text-only global rewrite pass after segment transcription.
- Provider-specific diarization APIs.

## Validation

Local validation was added for:

- metrics on single-pass drafts,
- ordered segment draft metrics,
- speaker-label detection,
- legacy draft decoding without metrics,
- prompt requirements for cleanup, optional speaker labels, and no fabrication.

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Result:

- 14 tests passed.

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
```

Result:

- `PhoneInboxCore`: 7 tests passed.
- `NoteDeliveryCore`: 4 tests passed.
- `LongAudioProcessingCore`: 4 tests passed.
- `WatchDeliveryCore`: 2 tests passed.
- `WatchMemoMessageCore`: 3 tests passed.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WatchMemoTranscriptQualitySimDerivedData \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoTranscriptQualityDeviceDerivedData \
  build
```

Installed and launched:

- iPhone app `com.watchmemo.app`.
- Watch app `com.watchmemo.app.watchkitapp`.

True long-recording quality validation is still pending. The next real-device
test should record a longer conversation-style sample and check whether the
model produces clear, meaning-preserving text with useful speaker labels only
when appropriate.
