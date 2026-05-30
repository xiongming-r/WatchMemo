# Phase 3 Log: Phone Inbox And Simulated Import

Date: 2026-05-30

## Goal

Build the iPhone-side inbox without depending on real Apple Watch hardware, so
we can keep developing locally while real-device WatchConnectivity validation is
deferred.

## What Changed

- Added `packages/PhoneInboxCore`, a small Swift package for inbox persistence.
- Added tests for importing a recording, copying audio, persisting metadata, and
  replacing an existing recording with the same ID.
- Reused the same inbox core source files in the iOS app target.
- Changed the iPhone app from an in-memory received list to a persisted inbox.
- Added a Debug-only simulated import button that generates a short local audio
  sample and imports it through the same store path.
- Added basic playback for inbox audio files.
- Kept the watch app build unchanged and passing.

## Important Decisions

- The watch-to-phone path remains the primary MVP architecture, but real
  hardware validation is paused.
- The iPhone inbox is now the stable boundary for later AI processing,
  transcription, export, and knowledge-base sync.
- Simulated local import is intentionally implemented in the iPhone app rather
  than relying on watch simulator containers, because app sandboxes cannot
  freely read other simulator app containers at runtime.
- `PhoneInboxStore` preserves the imported file extension instead of forcing
  `.m4a`, so local `.caf` samples and future watch `.m4a` files can both work.

## Validation

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

## Remaining Risks

- Real WatchConnectivity transfer still needs paired Apple Watch + iPhone
  validation later.
- The iPhone UI has only command-line build validation so far; manual simulator
  interaction should verify tapping the Debug import button and playback.
- No AI transcription or knowledge-base export is implemented yet.

## Next Candidate Phase

Phase 4 can start the AI text pipeline locally:

- Introduce an `TranscriptDraft` model.
- Add a fake transcription provider for deterministic local testing.
- Add an AI cleanup interface that preserves original meaning and removes
  filler words.
- Keep provider implementations swappable, so OpenAI/local/other APIs can be
  chosen later.
