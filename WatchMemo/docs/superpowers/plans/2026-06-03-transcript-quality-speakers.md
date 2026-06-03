# Transcript Quality And Speaker Metrics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add local text-quality metrics and lightweight speaker-label support for long-recording validation.

**Architecture:** Provider prompt guidance stays in `OpenAICompatibleTranscriptProvider`. Local draft metrics are computed in `TranscriptPipelineCore` and persisted on `TranscriptDraft`. The iPhone inbox row displays the metrics without changing recording, Obsidian export, or Watch delivery behavior.

**Tech Stack:** Swift, Swift Testing, SwiftUI, Codable draft persistence, OpenAI-compatible chat completions audio input.

---

### Task 1: Add Transcript Metrics Tests

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests asserting:

```swift
#expect(draft.qualityMetrics?.rawCharacterCount == draft.rawText.count)
#expect(draft.qualityMetrics?.cleanedCharacterCount == draft.cleanedText.count)
#expect(draft.qualityMetrics?.removedFillerCount == 2)
#expect(draft.qualityMetrics?.segmentCount == 1)
#expect(draft.qualityMetrics?.usedSegmentedProcessing == false)
```

Add a speaker-label test with cleaned text containing `说话人 A：...` and `说话人 B：...`, expecting `estimatedSpeakerCount == 2` and labels `["说话人 A", "说话人 B"]`.

Add a segmented draft test expecting `segmentCount == 3` and `usedSegmentedProcessing == true`.

Add a legacy JSON decode assertion expecting `qualityMetrics == nil`.

Add prompt assertions expecting the default instruction to contain `说话人 A`, `不要强行标注`, and `去除语气词`.

- [ ] **Step 2: Run failing tests**

Run:

```bash
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: failure because `qualityMetrics` and speaker metrics do not exist yet.

### Task 2: Implement Draft Metrics

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptDraft.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptPipeline.swift`

- [ ] **Step 1: Add `TranscriptQualityMetrics`**

Create a public `Codable`, `Equatable` struct with:

```swift
public let rawCharacterCount: Int
public let cleanedCharacterCount: Int
public let compressionRatio: Double?
public let removedFillerCount: Int
public let segmentCount: Int
public let usedSegmentedProcessing: Bool
public let speakerLabels: [String]
public let estimatedSpeakerCount: Int
public let hasSpeakerLabels: Bool
```

- [ ] **Step 2: Preserve legacy decoding**

Add `qualityMetrics: TranscriptQualityMetrics?` to `TranscriptDraft` and implement decoding so missing metrics decode as `nil`.

- [ ] **Step 3: Compute metrics in the pipeline**

Pass `segmentCount: 1` and `usedSegmentedProcessing: false` for single-pass drafts. Pass the segment URL count and `true` for segmented drafts. Detect speaker labels with line prefixes such as `说话人 A：`, `说话人A:`, and `Speaker A:`.

- [ ] **Step 4: Run package tests**

Run:

```bash
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: all TranscriptPipelineCore tests pass.

### Task 3: Strengthen Provider Prompt

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/OpenAICompatibleTranscriptProvider.swift`

- [ ] **Step 1: Update default instruction**

Require meaning-preserving cleanup, no fabricated facts, and optional speaker labels only when clearly distinguishable.

- [ ] **Step 2: Run package tests**

Run:

```bash
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: all TranscriptPipelineCore tests pass.

### Task 4: Display Metrics On iPhone

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`

- [ ] **Step 1: Add compact metric text**

Append draft metrics to existing diagnostics, for example `Text 120->96 80%`, `Segments 3`, and `Speakers 2`.

- [ ] **Step 2: Build iOS app**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoTranscriptQualitySimDerivedData build
```

Expected: build succeeds.

### Task 5: Update Phase Records And Verify Device Build

**Files:**
- Add: `WatchMemo/docs/phase-logs/phase-16-transcript-quality-speakers.md`
- Modify: `WatchMemo/docs/current-status.md`

- [ ] **Step 1: Record phase outcome**

Write the decision, changed behavior, test command list, and pending true long-recording validation.

- [ ] **Step 2: Run package regression tests**

Run:

```bash
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
```

Expected: all tests pass.

- [ ] **Step 3: Build and install on devices when connected**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoTranscriptQualityDeviceDerivedData build
xcrun devicectl device install app --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 /private/tmp/WatchMemoTranscriptQualityDeviceDerivedData/Build/Products/Debug-iphoneos/WatchMemo.app
xcrun devicectl device install app --device F855C270-A659-55F0-B2DE-9DDC98147813 /private/tmp/WatchMemoTranscriptQualityDeviceDerivedData/Build/Products/Debug-watchos/WatchMemoWatch.app
```

Expected: build and install succeed if both devices are connected.

