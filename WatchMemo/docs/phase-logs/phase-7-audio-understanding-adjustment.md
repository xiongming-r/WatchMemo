# Phase 7 Adjustment: Audio Understanding Provider

Date: 2026-06-01

## Goal

Adjust the first real API path for a model that supports direct audio
understanding. The app should send audio to a chat-style multimodal endpoint and
receive a cleaned note, not just a raw speech-to-text transcript.

## What Changed

- Changed the remote provider request from `POST /audio/transcriptions` to
  `POST /chat/completions`.
- Encoded audio as base64 in an `input_audio` content part.
- Added a faithful note-cleanup system instruction.
- Initially changed the default model to `mimo-v2.5-pro`.
- Added `PassthroughTranscriptCleaner` for already-cleaned remote model output.
- Updated the iPhone settings label to `Audio understanding`.
- Changed Debug sample import audio from `.caf` to `.m4a`.
- Kept `FakeTranscriptProvider` as the default app mode.

## Local Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS Simulator' \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'platform=iOS,id=00008130-000E61100E01001C' \
  build
```

Passed:

```sh
xcrun devicectl device install app \
  --device 00008130-000E61100E01001C \
  /Users/xiongming/Library/Developer/Xcode/DerivedData/WatchMemo-frtmoupdusycbgdhejxjibjkjpcu/Build/Products/Debug-iphoneos/WatchMemo.app
```

## True-Device Status

The iPhone app has been built and installed on the real iPhone once after:

- enabling Developer Mode
- trusting the Personal Team developer profile

Phase 7 is still not complete until the user confirms a real API request returns
a useful cleaned note on the iPhone, and then confirms Apple Watch recording
transfer plus API processing.

## Remaining Risks

- A later real iPhone test showed the MiMo-compatible request shape needs a
  data URI audio payload and `mimo-v2.5` as the documented audio default. See
  `phase-7-mimo-audio-schema-fix.md`.
- Debug import and real watch recordings now both use `.m4a`, but provider-side
  support still needs validation with the real API.
- The watch target signing still needs re-checking after the iPhone path passes.
