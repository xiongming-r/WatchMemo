# Phase 10 Transcription Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist iPhone-side AI processing state so imported watch recordings keep their audio, status, failure reason, and retry path across app restarts.

**Architecture:** Keep the audio file and recording manifest as the source of truth in `PhoneInboxCore`. Extend `InboxRecording` with durable transcription status metadata, expose narrow store methods for starting/succeeding/failing transcription, then have the iPhone `PhoneInboxViewModel` update those states around the existing transcript pipeline. The UI reads the persisted status and offers retry when a recording fails.

**Tech Stack:** Swift, Swift Testing, SwiftUI, local JSON manifests, existing `PhoneInboxCore` and `TranscriptPipelineCore` packages.

---

## File Structure

- Modify `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/InboxRecording.swift`
  - Add durable transcription statuses and metadata fields.
  - Add custom decoding defaults so existing installed app data still loads.
- Modify `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/PhoneInboxStore.swift`
  - Add `updateTranscriptionState(...)`.
  - Keep import behavior idempotent and audio-preserving.
- Modify `WatchMemo/packages/PhoneInboxCore/Tests/PhoneInboxCoreTests/PhoneInboxStoreTests.swift`
  - Add failing tests for status transitions and legacy manifest decoding.
- Modify `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
  - Replace purely in-memory processing state with persisted status transitions.
  - Reload recordings after each transition.
- Modify `WatchMemo/apps/companion/WatchMemo/ContentView.swift`
  - Display transcription status and failure reason per row.
  - Keep the sparkles button as retry for failed recordings.
- Add `WatchMemo/docs/phase-logs/phase-10-transcription-reliability.md`
  - Record scope, validation, and remaining risk.
- Modify `WatchMemo/docs/current-status.md`
  - Update latest checkpoint and next action.

## Task 1: PhoneInboxCore Persistent State

**Files:**
- Modify: `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/InboxRecording.swift`
- Modify: `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/PhoneInboxStore.swift`
- Test: `WatchMemo/packages/PhoneInboxCore/Tests/PhoneInboxCoreTests/PhoneInboxStoreTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests that prove:

```swift
@Test("transcription state transitions persist without changing the audio file")
func transcriptionStateTransitionsPersist() throws {
    let root = try makeTemporaryDirectory()
    let source = root.appendingPathComponent("source.m4a")
    try Data("audio bytes".utf8).write(to: source)
    let id = UUID(uuidString: "12345678-1111-2222-3333-444444444444")!
    let store = PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox"))
    let imported = try store.importRecording(
        fileURL: source,
        metadata: InboxImportMetadata(
            id: id,
            originalFileName: "voice.m4a",
            createdAt: Date(timeIntervalSince1970: 100),
            durationSeconds: 9,
            source: .watchConnectivity
        )
    )

    try store.updateTranscriptionState(
        recordingID: id,
        status: .transcribing,
        errorMessage: nil,
        attemptedAt: Date(timeIntervalSince1970: 200),
        incrementsAttemptCount: true
    )
    try store.updateTranscriptionState(
        recordingID: id,
        status: .transcriptionFailed,
        errorMessage: "network offline",
        attemptedAt: Date(timeIntervalSince1970: 220),
        incrementsAttemptCount: false
    )

    let reloaded = try PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox")).loadRecordings()
    #expect(reloaded.first?.id == id)
    #expect(reloaded.first?.status == .transcriptionFailed)
    #expect(reloaded.first?.transcriptionErrorMessage == "network offline")
    #expect(reloaded.first?.transcriptionAttemptCount == 1)
    #expect(reloaded.first?.lastTranscriptionAttemptAt == Date(timeIntervalSince1970: 220))
    #expect(reloaded.first?.storedFileName == imported.storedFileName)
    #expect(try Data(contentsOf: reloaded.first!.fileURL) == Data("audio bytes".utf8))
}
```

Add a second test that writes a legacy JSON manifest without the new metadata fields and expects defaults:

```swift
@Test("legacy recording manifests decode with transcription defaults")
func legacyRecordingManifestDecodesWithDefaults() throws {
    let root = try makeTemporaryDirectory()
    let inbox = root.appendingPathComponent("Inbox")
    let audio = inbox.appendingPathComponent("Audio", isDirectory: true)
    try FileManager.default.createDirectory(at: audio, withIntermediateDirectories: true)
    try Data("legacy audio".utf8).write(to: audio.appendingPathComponent("legacy.m4a"))
    let json = """
    [
      {
        "createdAt" : 100,
        "durationSeconds" : 3.5,
        "fileURL" : "\(audio.appendingPathComponent("legacy.m4a").path)",
        "id" : "99999999-8888-7777-6666-555555555555",
        "importedAt" : 120,
        "originalFileName" : "legacy.m4a",
        "source" : "watchConnectivity",
        "status" : "readyForTranscription",
        "storedFileName" : "legacy.m4a"
      }
    ]
    """
    try json.data(using: .utf8)!.write(to: inbox.appendingPathComponent("recordings.json"))

    let recordings = try PhoneInboxStore(rootDirectory: inbox).loadRecordings()

    #expect(recordings.first?.status == .readyForTranscription)
    #expect(recordings.first?.transcriptionErrorMessage == nil)
    #expect(recordings.first?.transcriptionAttemptCount == 0)
    #expect(recordings.first?.lastTranscriptionAttemptAt == nil)
}
```

- [ ] **Step 2: Run RED**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Expected: fail because `updateTranscriptionState`, `.transcribing`, `.transcriptionFailed`, and metadata properties do not exist yet.

- [ ] **Step 3: Implement the persistent state**

Add statuses:

```swift
case readyForTranscription
case transcribing
case draftReady
case transcriptionFailed
```

Add fields:

```swift
public var transcriptionErrorMessage: String?
public var transcriptionAttemptCount: Int
public var lastTranscriptionAttemptAt: Date?
```

Add `PhoneInboxStore.updateTranscriptionState(...)` that loads the manifest, updates the matching recording, preserves audio metadata, increments attempts only when requested, and writes atomically.

- [ ] **Step 4: Run GREEN**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Expected: all tests pass.

## Task 2: iPhone Processing Flow

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`

- [ ] **Step 1: Update ViewModel transitions**

Around `processTranscript(for:)`:

```swift
try store.updateTranscriptionState(
    recordingID: recording.id,
    status: .transcribing,
    errorMessage: nil,
    attemptedAt: Date(),
    incrementsAttemptCount: true
)
reload(status: "Transcribing recording")
```

On success:

```swift
try store.updateTranscriptionState(
    recordingID: recording.id,
    status: .draftReady,
    errorMessage: nil,
    attemptedAt: Date(),
    incrementsAttemptCount: false
)
reload(status: "Draft ready")
```

On failure:

```swift
try? store.updateTranscriptionState(
    recordingID: recording.id,
    status: .transcriptionFailed,
    errorMessage: error.localizedDescription,
    attemptedAt: Date(),
    incrementsAttemptCount: false
)
reload(status: "Draft failed: \(error.localizedDescription)")
```

- [ ] **Step 2: Update row UI**

Show a compact status line derived from `recording.status`, attempts, and error message. Keep the action button enabled for failed recordings and use retry icon/text accessibility when appropriate.

- [ ] **Step 3: Build the iOS app**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase10ReliabilitySimDerivedData build
```

Expected: build succeeds.

## Task 3: Docs And Verification

**Files:**
- Add: `WatchMemo/docs/phase-logs/phase-10-transcription-reliability.md`
- Modify: `WatchMemo/docs/current-status.md`

- [ ] **Step 1: Record Phase 10**

Document:

- Scope: durable iPhone transcription status and retry.
- Out of scope: long-audio chunking, background upload guarantees, file-level Obsidian export.
- Validation: package tests and simulator/device builds.
- Next risk: model max audio length and chunk merge quality.

- [ ] **Step 2: Run full relevant verification**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase10ReliabilitySimDerivedData build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoPhase10ReliabilityWatchDerivedData build
```

Expected: all commands pass.

- [ ] **Step 3: Commit**

Stage only Phase 10 files and necessary project changes:

```bash
git add WatchMemo/packages/PhoneInboxCore WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift WatchMemo/apps/companion/WatchMemo/ContentView.swift WatchMemo/docs/current-status.md WatchMemo/docs/phase-logs/phase-10-transcription-reliability.md WatchMemo/docs/superpowers/plans/2026-06-02-phase-10-transcription-reliability.md
git commit -m "feat: persist transcription processing state"
```

## Self-Review

- Spec coverage: The plan covers durable status, visible failure, retry, app restart recovery, and no audio deletion.
- Placeholder scan: No placeholder tasks remain.
- Type consistency: The status names and method signatures match across tests, store, ViewModel, and UI steps.
