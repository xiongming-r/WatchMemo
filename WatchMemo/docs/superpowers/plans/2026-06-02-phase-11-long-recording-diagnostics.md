# Phase 11 Long Recording Diagnostics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist and display enough recording and AI timing metrics to diagnose real long-recording limits before implementing chunking.

**Architecture:** Extend the existing iPhone inbox manifest with diagnostic fields instead of adding a separate analytics subsystem. The store records audio byte size during import and AI duration during transcription state updates. The iPhone row displays these metrics compactly so real-device tests can reveal payload-size, model-duration, or export bottlenecks.

**Tech Stack:** Swift, Swift Testing, SwiftUI, local JSON manifests, existing `PhoneInboxCore`.

---

## File Structure

- Modify `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/InboxRecording.swift`
  - Add `audioByteCount` and `lastTranscriptionDurationSeconds`.
  - Decode legacy manifests with safe defaults.
- Modify `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/PhoneInboxStore.swift`
  - Capture copied audio file size at import.
  - Persist AI duration through `updateTranscriptionState(...)`.
- Modify `WatchMemo/packages/PhoneInboxCore/Tests/PhoneInboxCoreTests/PhoneInboxStoreTests.swift`
  - Add failing tests for audio byte size, AI duration, and legacy defaults.
- Modify `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
  - Measure elapsed provider time and persist it on success/failure.
- Modify `WatchMemo/apps/companion/WatchMemo/ContentView.swift`
  - Display audio size and AI processing duration in each recording row.
- Add `WatchMemo/docs/phase-logs/phase-11-long-recording-diagnostics.md`
  - Record scope, validation, and next long-recording experiment.
- Modify `WatchMemo/docs/current-status.md`
  - Point future sessions at Phase 11.

## Task 1: Metrics Persistence

**Files:**
- Modify: `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/InboxRecording.swift`
- Modify: `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/PhoneInboxStore.swift`
- Test: `WatchMemo/packages/PhoneInboxCore/Tests/PhoneInboxCoreTests/PhoneInboxStoreTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests that assert:

- imported recordings persist `audioByteCount`;
- `updateTranscriptionState(...)` can persist `durationSeconds`;
- legacy manifests decode `audioByteCount` and `lastTranscriptionDurationSeconds` as `nil`.

- [ ] **Step 2: Run RED**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Expected: fail because metric fields and the new state-update parameter do not exist.

- [ ] **Step 3: Implement minimal persistence**

Add fields:

```swift
public let audioByteCount: Int64?
public var lastTranscriptionDurationSeconds: TimeInterval?
```

Add an optional `durationSeconds` argument to `updateTranscriptionState(...)`, defaulting to `nil`, and save it into `lastTranscriptionDurationSeconds`.

- [ ] **Step 4: Run GREEN**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Expected: all tests pass.

## Task 2: iPhone Timing And UI

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`

- [ ] **Step 1: Measure provider time**

Capture `let transcriptionStartedAt = Date()` before calling the provider and pass elapsed seconds to `updateTranscriptionState(...)` on success or failure.

- [ ] **Step 2: Display metrics**

Add a compact row line containing:

- audio size such as `11.4 MB`;
- AI time such as `AI 18.2s`;
- attempt count already shown by Phase 10 remains in status text.

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase11DiagnosticsSimDerivedData build
```

Expected: build succeeds.

## Task 3: Docs And Verification

**Files:**
- Add: `WatchMemo/docs/phase-logs/phase-11-long-recording-diagnostics.md`
- Modify: `WatchMemo/docs/current-status.md`

- [ ] **Step 1: Record Phase 11**

Document that this phase prepares for long recordings by measuring audio size and AI request duration. Long-audio chunking remains out of scope.

- [ ] **Step 2: Run verification**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase11DiagnosticsSimDerivedData build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoPhase11DiagnosticsWatchDerivedData build
```

Expected: all commands pass.

- [ ] **Step 3: Commit**

```bash
git add WatchMemo/packages/PhoneInboxCore WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift WatchMemo/apps/companion/WatchMemo/ContentView.swift WatchMemo/docs/current-status.md WatchMemo/docs/phase-logs/phase-11-long-recording-diagnostics.md WatchMemo/docs/superpowers/plans/2026-06-02-phase-11-long-recording-diagnostics.md
git commit -m "feat: add long recording diagnostics"
```

## Self-Review

- Scope is limited to diagnostics and does not implement chunking.
- Metrics are attached to the persisted recording manifest, so they survive restarts.
- Legacy manifests keep loading because new fields are optional.
