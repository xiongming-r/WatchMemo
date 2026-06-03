# Long Audio Segmentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add adaptive iPhone-side segmented transcript processing for long or large Watch recordings.

**Architecture:** Keep model decisions in a pure Swift package, keep audio export in the iPhone app, and extend the existing transcript pipeline to merge ordered segment transcripts into one draft.

**Tech Stack:** Swift, Swift Testing, AVFoundation, WatchConnectivity, Xcode command-line builds.

---

### Task 1: Long Audio Strategy

**Files:**
- Create: `WatchMemo/packages/LongAudioProcessingCore/Package.swift`
- Create: `WatchMemo/packages/LongAudioProcessingCore/Sources/LongAudioProcessingCore/LongAudioProcessingCore.swift`
- Create: `WatchMemo/packages/LongAudioProcessingCore/Tests/LongAudioProcessingCoreTests/LongAudioProcessingTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
@testable import LongAudioProcessingCore

@Suite("Long audio processing")
struct LongAudioProcessingTests {
    @Test("keeps short small recordings as single pass")
    func shortSmallRecordingUsesSinglePass() {
        let decision = LongAudioProcessingStrategy.default.decision(
            durationSeconds: 9 * 60,
            audioByteCount: 4 * 1_024 * 1_024
        )

        #expect(decision == .singlePass)
    }

    @Test("splits long recordings")
    func longRecordingUsesSegments() {
        let decision = LongAudioProcessingStrategy.default.decision(
            durationSeconds: 11 * 60,
            audioByteCount: 2 * 1_024 * 1_024
        )

        #expect(decision == .segmented(segmentDurationSeconds: 300, overlapSeconds: 15))
    }

    @Test("splits large recordings")
    func largeRecordingUsesSegments() {
        let decision = LongAudioProcessingStrategy.default.decision(
            durationSeconds: 2 * 60,
            audioByteCount: 6 * 1_024 * 1_024
        )

        #expect(decision == .segmented(segmentDurationSeconds: 300, overlapSeconds: 15))
    }

    @Test("plans overlapped segments in order")
    func plansOverlappedSegments() {
        let plan = AudioSegmentPlan.make(
            durationSeconds: 12 * 60,
            segmentDurationSeconds: 300,
            overlapSeconds: 15
        )

        #expect(plan.segments.map(\\.index) == [0, 1, 2])
        #expect(plan.segments[0].startSeconds == 0)
        #expect(plan.segments[0].endSeconds == 300)
        #expect(plan.segments[1].startSeconds == 285)
        #expect(plan.segments[1].endSeconds == 585)
        #expect(plan.segments[2].startSeconds == 570)
        #expect(plan.segments[2].endSeconds == 720)
    }
}
```

- [ ] **Step 2: Verify tests fail**

Run: `swift test --package-path WatchMemo/packages/LongAudioProcessingCore`

Expected: fail because strategy and plan types do not exist.

- [ ] **Step 3: Implement minimal strategy and plan**

Implement `LongAudioProcessingDecision`, `LongAudioProcessingStrategy`,
`AudioSegment`, and `AudioSegmentPlan` with the documented thresholds.

- [ ] **Step 4: Verify tests pass**

Run: `swift test --package-path WatchMemo/packages/LongAudioProcessingCore`

Expected: all tests pass.

### Task 2: Segment Draft Merging

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptPipeline.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] **Step 1: Write failing merge test**

Add a test with a custom provider that returns different text per segment URL,
then assert the final draft preserves segment order and formats one structured
note.

- [ ] **Step 2: Implement `makeDraftFromSegments`**

Transcribe each segment in order, combine non-empty texts with blank lines, run
the existing cleaner and note formatter once.

- [ ] **Step 3: Verify tests pass**

Run: `swift test --package-path WatchMemo/packages/TranscriptPipelineCore`

Expected: all tests pass.

### Task 3: iPhone Audio Segment Export

**Files:**
- Create: `WatchMemo/apps/companion/WatchMemo/AudioSegmentExporter.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`

- [ ] **Step 1: Implement `AudioSegmentExporter`**

Use `AVURLAsset`, `AVAssetExportSession`, `AVAssetExportPresetAppleM4A`, and
temporary files under `FileManager.default.temporaryDirectory`.

- [ ] **Step 2: Use strategy in `processTranscript`**

If strategy returns `.singlePass`, keep the current path. If it returns
`.segmented`, export segment files, call `makeDraftFromSegments`, and remove
temporary segment files after completion.

- [ ] **Step 3: Build simulator**

Run: `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoLongAudioSimDerivedData build`

Expected: `BUILD SUCCEEDED`.

### Task 4: Docs, Device Install, Commit

**Files:**
- Modify: `WatchMemo/docs/current-status.md`
- Create: `WatchMemo/docs/phase-logs/phase-15-long-audio-segmentation.md`

- [ ] **Step 1: Document Phase 15**

Record thresholds, segment length, overlap, validation commands, and true-device
test guidance.

- [ ] **Step 2: Build and install real devices**

Run the real iPhone destination build, install the iPhone app, install the
Watch app, and launch both apps.

- [ ] **Step 3: Commit**

```bash
git add WatchMemo/apps/companion/WatchMemo/AudioSegmentExporter.swift \
  WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift \
  WatchMemo/packages/LongAudioProcessingCore \
  WatchMemo/packages/TranscriptPipelineCore \
  WatchMemo/docs/current-status.md \
  WatchMemo/docs/phase-logs/phase-15-long-audio-segmentation.md \
  WatchMemo/docs/superpowers/specs/2026-06-03-long-audio-segmentation-design.md \
  WatchMemo/docs/superpowers/plans/2026-06-03-long-audio-segmentation.md
git commit -m "feat: add adaptive long audio segmentation"
```
