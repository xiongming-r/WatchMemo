# Phase 4 Log: Local Transcript Pipeline

Date: 2026-05-30

## Goal

Create a locally testable path from an inbox recording to a cleaned text draft,
without depending on a real transcription or AI provider yet.

## What Changed

- Added `packages/TranscriptPipelineCore`, a Swift package for transcript draft
  generation.
- Added a provider protocol so real providers can be swapped in later.
- Added `FakeTranscriptProvider` for deterministic local development.
- Added `ConservativeTranscriptCleaner`, which removes a small set of common
  filler words while preserving the raw text.
- Added `TranscriptDraft` so the app can keep raw text, cleaned text, removed
  fillers, status, and recording linkage together.
- Added iPhone Inbox UI support for generating and refreshing a local draft per
  recording.

## Important Decisions

- This phase intentionally does not call a real AI or speech-to-text API.
- The raw transcript is kept alongside the cleaned version, because preserving
  original meaning matters more than making the cleaned text look polished.
- The first cleaner is conservative and testable. Later model-based cleanup
  should satisfy the same contract: do not silently discard meaning.
- Transcript state is currently in memory in the iPhone app; persistence can be
  added after the draft model stabilizes.

## Validation

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

## Remaining Risks

- The fake provider does not prove real audio transcription quality.
- The cleanup rules are intentionally simple; Chinese and English filler removal
  will need model-backed evaluation with real recordings.
- Transcript drafts are not persisted yet.
- Real WatchConnectivity transfer is still deferred until paired hardware is
  available.

## Next Candidate Phase

Phase 5 can add a real provider boundary:

- Add a `ProviderConfiguration` model.
- Add an OpenAI-compatible provider or local command-line provider behind the
  same `TranscriptProvider` protocol.
- Persist transcript drafts.
- Add export/sync target planning for Obsidian or another knowledge base.
