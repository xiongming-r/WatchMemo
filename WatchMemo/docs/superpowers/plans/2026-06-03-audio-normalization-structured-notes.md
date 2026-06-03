# Audio Normalization And Structured Notes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve weak-recording transcription usefulness by enhancing upload audio and parsing real structured summaries.

**Architecture:** `TranscriptPipelineCore` handles provider-output structure and metrics. `PhoneInboxViewModel` handles iPhone-only AVFoundation upload preprocessing. Watch recording files remain unchanged; provider calls use temporary enhanced audio when available.

**Tech Stack:** Swift, Swift Testing, SwiftUI, AVFoundation, Codable draft persistence, OpenAI-compatible chat completions audio input.

---

### Task 1: Structured Note And Speaker Tests

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] **Step 1: Add failing tests**

Add tests that assert:

```swift
let formatter = TranscriptNoteFormatter()
let note = formatter.format(text: markdown, createdAt: date)
#expect(note.title == "茶歇试吃讨论")
#expect(note.summary == "两位说话人讨论试吃零食、来源和口味判断。")
#expect(note.body.contains("说话人A"))
#expect(note.actionItems == ["下次记录时靠近声源。"])
#expect(note.tags == ["试吃", "对话"])
```

Add a speaker metric test for `**说话人A（女）：**` and `**说话人B（男）：**`, expecting two speaker labels.

Add a provider prompt test expecting `## 摘要`, `## 关键结论`, `## 待办`, and `不要强行标注`.

- [ ] **Step 2: Run red test**

Run:

```bash
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: fail because formatter and speaker detection do not yet parse the new shapes.

### Task 2: Implement Structured Parsing

**Files:**
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptNote.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/TranscriptPipeline.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/OpenAICompatibleTranscriptProvider.swift`

- [ ] **Step 1: Parse Markdown sections**

Implement section extraction for `# title`, `## 摘要`, `## 正文`, `## 对话整理`, `## 关键结论`, `## 待办`, and `## 标签`.

- [ ] **Step 2: Keep fallback behavior**

If no useful sections exist, retain existing first-sentence summary and prefix-based action/tag extraction.

- [ ] **Step 3: Improve speaker label regex**

Detect labels with optional Markdown bold wrappers, no-space names, and descriptive parentheses.

- [ ] **Step 4: Update provider instruction**

Ask the model to output structured Markdown sections while preserving the no-fabrication and optional speaker-label rules.

- [ ] **Step 5: Run green test**

Run:

```bash
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Expected: all tests pass.

### Task 3: Add iPhone Upload Audio Preprocessing

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`

- [ ] **Step 1: Add `AudioUploadPreprocessor`**

Add a private helper that reads audio with `AVAudioFile`, computes RMS and peak, applies conservative dynamic gain to mono/stereo PCM samples, writes a temporary `.wav`, and reports before/after diagnostics.

- [ ] **Step 2: Use enhanced file for provider calls**

For single-pass recordings, preprocess `recording.fileURL` and call `makeDraft` with the enhanced file URL when available. For segmented recordings, preprocess each segment before `makeDraftFromSegments`.

- [ ] **Step 3: Clean temporary files**

Track enhanced URLs in the existing temporary URL cleanup path.

- [ ] **Step 4: Show preprocessing status**

Add status text such as `Enhancing audio` and include a compact `Enhanced audio` diagnostic when preprocessing succeeds.

- [ ] **Step 5: Build simulator app**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoAudioNormalizeSimDerivedData build
```

Expected: build succeeds.

### Task 4: Phase Records And Device Validation

**Files:**
- Add: `WatchMemo/docs/phase-logs/phase-17-audio-normalization-structured-notes.md`
- Modify: `WatchMemo/docs/current-status.md`

- [ ] **Step 1: Record phase evidence**

Document the 1:30 recording diagnostics, behavior changes, validation commands, and remaining true-device quality test.

- [ ] **Step 2: Run package regression tests**

Run:

```bash
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
```

Expected: all tests pass.

- [ ] **Step 3: Build and install when devices are connected**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoAudioNormalizeDeviceDerivedData build
xcrun devicectl device install app --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 /private/tmp/WatchMemoAudioNormalizeDeviceDerivedData/Build/Products/Debug-iphoneos/WatchMemo.app
xcrun devicectl device install app --device F855C270-A659-55F0-B2DE-9DDC98147813 /private/tmp/WatchMemoAudioNormalizeDeviceDerivedData/Build/Products/Debug-watchos/WatchMemoWatch.app
```

Expected: build and install succeed if devices are connected.

