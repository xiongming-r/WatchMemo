# Phase 6 OpenAI Compatible Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an OpenAI-compatible remote transcription provider behind the existing `TranscriptProvider` protocol.

**Architecture:** Keep provider code in `TranscriptPipelineCore`. Add an injectable HTTP client so tests can validate request shape and response parsing without network calls. Keep the iPhone app default on the fake provider until API key storage and settings UI are designed.

**Tech Stack:** Swift Package Manager, Swift Testing, Foundation networking, multipart/form-data request construction.

---

### Task 1: OpenAI-Compatible Provider Core

**Files:**
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/OpenAICompatibleTranscriptProvider.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/ProviderConfiguration.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests proving that the provider:

- sends `POST` to `<endpointURL>/audio/transcriptions`
- uses `Authorization: Bearer <apiKey>`
- sends multipart fields for `model`, optional `prompt`, optional `response_format`
- parses `{ "text": "..." }` into raw transcript text
- throws a provider error for non-2xx HTTP responses

- [ ] **Step 2: Run test to verify it fails**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: FAIL because `OpenAICompatibleTranscriptProvider` and HTTP test seams do not exist.

- [ ] **Step 3: Implement minimal code**

Implement:

- `TranscriptHTTPClient`
- `URLSessionTranscriptHTTPClient`
- `OpenAICompatibleTranscriptProvider`
- `OpenAICompatibleTranscriptProviderError`
- `ProviderConfiguration.openAICompatible(endpointURL:model:)`

- [ ] **Step 4: Run tests**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: PASS.

### Task 2: Xcode Target Wiring

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add provider source to iOS target**

Add `OpenAICompatibleTranscriptProvider.swift` to the iOS `WatchMemo` target only.

- [ ] **Step 2: Build iPhone target**

Run:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Expected: BUILD SUCCEEDED.

### Task 3: Documentation And Commit

**Files:**
- Create: `WatchMemo/docs/phase-logs/phase-6-openai-compatible-provider.md`
- Modify: `WatchMemo/docs/current-status.md`
- Modify: `WatchMemo/docs/development.md`

- [ ] **Step 1: Record the phase**

Document that the provider adapter exists and is tested, but the app still uses
the fake provider until API key handling/settings are added.

- [ ] **Step 2: Verify**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/PhoneInboxCore
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build
```

Expected: all pass.

- [ ] **Step 3: Commit**

```sh
git add WatchMemo
git commit -m "feat: add openai compatible transcript provider"
```
