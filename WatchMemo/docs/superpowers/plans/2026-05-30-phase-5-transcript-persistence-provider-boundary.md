# Phase 5 Transcript Persistence Provider Boundary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist transcript drafts locally and define a provider configuration boundary without calling a real API yet.

**Architecture:** Extend `TranscriptPipelineCore` with `TranscriptDraftStore` and `ProviderConfiguration`. Wire the iPhone app to load drafts on launch and save drafts after generation, while still using the fake provider by default.

**Tech Stack:** Swift Package Manager, Swift Testing, SwiftUI, JSON file persistence, existing Xcode companion project.

---

### Task 1: Draft Store And Provider Configuration

**Files:**
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptDraftStore.swift`
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/ProviderConfiguration.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests proving that:

```swift
let store = TranscriptDraftStore(rootDirectory: root.appendingPathComponent("Drafts"))
try store.save(draft)
let reloaded = try store.loadDrafts()
#expect(reloaded == [draft])
```

and:

```swift
let configuration = ProviderConfiguration.fake
#expect(configuration.kind == .fake)
#expect(configuration.displayName == "Fake local provider")
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: FAIL because `TranscriptDraftStore` and `ProviderConfiguration` do not exist.

- [ ] **Step 3: Implement minimal code**

`TranscriptDraftStore` writes an array of drafts to `transcript-drafts.json`.
Saving a draft replaces any existing draft with the same `recordingID`.

`ProviderConfiguration` is a Codable/Equatable struct with a `kind`,
`displayName`, optional `endpointURL`, optional `model`, and optional
`commandPath`.

- [ ] **Step 4: Run tests**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: PASS.

### Task 2: iPhone App Draft Persistence

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo.xcodeproj/project.pbxproj`
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`

- [ ] **Step 1: Add new core files to iOS target**

Add `TranscriptDraftStore.swift` and `ProviderConfiguration.swift` to the
`WatchMemo` iOS target only.

- [ ] **Step 2: Load saved drafts during view model init**

`PhoneInboxViewModel` receives a `TranscriptDraftStore`, loads its drafts into
`transcriptDrafts`, and keeps failures visible in `statusText`.

- [ ] **Step 3: Save drafts after generation**

When `processTranscript(for:)` creates a draft, call `draftStore.save(draft)`
before publishing it into `transcriptDrafts`.

- [ ] **Step 4: Build iPhone target**

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
- Create: `WatchMemo/docs/phase-logs/phase-5-transcript-persistence-provider-boundary.md`
- Modify: `WatchMemo/docs/current-status.md`
- Modify: `WatchMemo/docs/development.md`

- [ ] **Step 1: Record the phase**

Document that drafts are now persisted and provider configuration exists, but no
real API call has been implemented.

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
git commit -m "feat: persist transcript drafts"
```
