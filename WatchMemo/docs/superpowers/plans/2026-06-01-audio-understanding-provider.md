# Audio Understanding Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the real remote provider send audio to an OpenAI-compatible chat endpoint for direct audio understanding.

**Architecture:** Reuse the existing `TranscriptProvider` boundary and keep the provider name compatible with existing app wiring. Change the remote request from multipart transcription to JSON chat completion with base64 audio, and bypass local filler cleanup for this already-cleaned provider output.

**Tech Stack:** Swift, Swift Testing, SwiftUI, URLRequest, Xcode iOS/watchOS targets.

---

### Task 1: Lock Request Shape With Tests

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] Replace the transcription request test with one that expects `POST /chat/completions`.
- [ ] Assert JSON body includes `model`, `input_audio`, base64 audio data, audio format, and the cleanup instruction.
- [ ] Update failure tests to use `/chat/completions`.

### Task 2: Implement Audio Understanding Provider

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/OpenAICompatibleTranscriptProvider.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/ProviderRuntimeSettings.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/ProviderConfiguration.swift`

- [ ] Build JSON chat completion requests instead of multipart transcription requests.
- [ ] Encode audio file data as base64.
- [ ] Parse `choices[0].message.content`.
- [ ] Default model to `mimo-v2.5-pro`.

### Task 3: Avoid Double Cleanup

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptCleaner.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`

- [ ] Add a pass-through cleaner for already-cleaned provider output.
- [ ] Use pass-through cleanup for the remote audio-understanding provider.
- [ ] Keep conservative cleanup for the fake provider.

### Task 4: Update UI Copy And Docs

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo/ProviderSettingsView.swift`
- Modify: `WatchMemo/docs/current-status.md`
- Modify: `WatchMemo/docs/development.md`
- Create: `WatchMemo/docs/phase-logs/phase-7-audio-understanding-adjustment.md`

- [ ] Change setting labels from transcription-only wording to audio understanding wording.
- [ ] Record that Phase 7 now targets direct audio understanding.
- [ ] Keep true-device validation as pending until the user confirms on hardware.

### Task 5: Verify

- [ ] Run `swift test --package-path WatchMemo/packages/TranscriptPipelineCore`.
- [ ] Run `swift test --package-path WatchMemo/packages/PhoneInboxCore`.
- [ ] Run iOS simulator build.
- [ ] Run watchOS simulator build.
- [ ] Run real iPhone build and install.
