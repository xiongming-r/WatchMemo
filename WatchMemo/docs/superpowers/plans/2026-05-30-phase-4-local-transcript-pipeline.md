# Phase 4 Local Transcript Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a locally testable transcript draft pipeline that turns an inbox recording into raw text plus a conservative cleaned note.

**Architecture:** Add a new `TranscriptPipelineCore` Swift package with provider, cleaner, and draft models. The iPhone app uses a fake provider for now, while the provider protocol keeps OpenAI, local Whisper, or other APIs swappable later.

**Tech Stack:** Swift Package Manager, Swift Testing, SwiftUI, AVFoundation playback already present in the iPhone app.

---

### Task 1: Transcript Pipeline Core

**Files:**
- Create: `WatchMemo/packages/TranscriptPipelineCore/Package.swift`
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptDraft.swift`
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptPipeline.swift`
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptCleaner.swift`
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/FakeTranscriptProvider.swift`
- Test: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Foundation
import Testing
@testable import TranscriptPipelineCore

@Suite("Transcript pipeline")
struct TranscriptPipelineTests {
    @Test("cleaner removes common filler words while keeping content")
    func cleanerRemovesFillers() {
        let cleaner = ConservativeTranscriptCleaner()
        let result = cleaner.clean("嗯 那个 今天会议就是决定先做手表录音, 呃 下周验证同步。")

        #expect(result.cleanedText == "今天会议决定先做手表录音, 下周验证同步。")
        #expect(result.removedFillers == ["嗯", "那个", "就是", "呃"])
        #expect(result.originalText.contains("今天会议"))
    }

    @Test("pipeline keeps raw text and cleaned text in one draft")
    func pipelineCreatesDraft() async throws {
        let provider = FakeTranscriptProvider(
            fixedText: "um record the pricing idea, you know, make it easier to review later."
        )
        let pipeline = TranscriptPipeline(
            provider: provider,
            cleaner: ConservativeTranscriptCleaner(),
            now: { Date(timeIntervalSince1970: 1_778_900_000) }
        )
        let recordingID = UUID(uuidString: "99999999-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!

        let draft = try await pipeline.makeDraft(
            recordingID: recordingID,
            audioFileURL: URL(fileURLWithPath: "/tmp/sample.m4a"),
            hint: "pricing idea"
        )

        #expect(draft.recordingID == recordingID)
        #expect(draft.rawText == "um record the pricing idea, you know, make it easier to review later.")
        #expect(draft.cleanedText == "record the pricing idea, make it easier to review later.")
        #expect(draft.status == .cleaned)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: FAIL because `TranscriptPipelineCore` types do not exist yet.

- [ ] **Step 3: Implement minimal core**

Implement `TranscriptDraft`, `TranscriptCleanupResult`, `TranscriptProvider`,
`ConservativeTranscriptCleaner`, `FakeTranscriptProvider`, and
`TranscriptPipeline` exactly around the tested behavior.

- [ ] **Step 4: Run test to verify it passes**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: PASS.

### Task 2: iPhone App Integration

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo.xcodeproj/project.pbxproj`
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`

- [ ] **Step 1: Add core files to iOS target**

Add the `TranscriptPipelineCore` source files to the `WatchMemo` iOS target only.

- [ ] **Step 2: Add transcript state to the view model**

`PhoneInboxViewModel` should hold:

```swift
@Published private(set) var transcriptDrafts: [InboxRecording.ID: TranscriptDraft] = [:]
@Published private(set) var processingTranscriptIDs: Set<InboxRecording.ID> = []
```

Add:

```swift
func processTranscript(for recording: InboxRecording) async
```

This method uses `TranscriptPipeline(provider: FakeTranscriptProvider(), cleaner: ConservativeTranscriptCleaner())`.

- [ ] **Step 3: Add transcript action to the row**

Each recording row gets a sparkle button. It shows a progress indicator while
processing and shows cleaned text after a draft exists.

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

### Task 3: Documentation And Checkpoint

**Files:**
- Create: `WatchMemo/docs/phase-logs/phase-4-local-transcript-pipeline.md`
- Modify: `WatchMemo/docs/current-status.md`
- Modify: `WatchMemo/docs/development.md`

- [ ] **Step 1: Record the phase**

Document the new pipeline, validation commands, and the fact that this is not a
real model/API integration yet.

- [ ] **Step 2: Verify all relevant commands**

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
git commit -m "feat: add local transcript pipeline"
```
