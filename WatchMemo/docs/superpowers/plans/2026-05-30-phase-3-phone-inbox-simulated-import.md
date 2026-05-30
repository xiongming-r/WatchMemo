# Phase 3 Phone Inbox Simulated Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iPhone-side recording inbox that can be validated locally without real Apple Watch transfer.

**Architecture:** Put reusable inbox persistence in a small Swift package, then compile the same source files into the iOS app target. `PhoneConnectivityReceiver` and a new simulator/debug importer both write into `PhoneInboxStore`; the UI reads from a view model and can play local audio.

**Tech Stack:** Swift Package Manager, XCTest, SwiftUI, AVFoundation, Xcode 26.2.

---

### Task 1: Add Phone Inbox Core With Tests

**Files:**
- Create: `WatchMemo/packages/PhoneInboxCore/Package.swift`
- Create: `WatchMemo/packages/PhoneInboxCore/Tests/PhoneInboxCoreTests/PhoneInboxStoreTests.swift`
- Create: `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/InboxRecording.swift`
- Create: `WatchMemo/packages/PhoneInboxCore/Sources/PhoneInboxCore/PhoneInboxStore.swift`

- [ ] **Step 1: Write failing tests**

Test that importing a file copies it to an inbox directory, writes metadata, and reloads after store recreation.

- [ ] **Step 2: Verify tests fail**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Expected: fail because `PhoneInboxStore` and `InboxRecording` do not exist yet.

- [ ] **Step 3: Implement minimal core**

Add model and persistence store with JSON metadata.

- [ ] **Step 4: Verify tests pass**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Expected: pass.

### Task 2: Connect Inbox Core To iOS App

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo.xcodeproj/project.pbxproj`
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneConnectivityReceiver.swift`
- Create: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/WatchMemoApp.swift`

- [ ] **Step 1: Add core files to iOS target**

Reference the package source files in the iOS target so the app can use the same tested types.

- [ ] **Step 2: Change receiver to write into store**

When WatchConnectivity receives a file, import it through `PhoneInboxStore`.

- [ ] **Step 3: Add view model**

`PhoneInboxViewModel` loads recordings, exposes status text, and imports sample files for simulator-only testing.

- [ ] **Step 4: Build iOS target**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
```

Expected: pass.

### Task 3: Add Inbox UI And Playback

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`
- Create: `WatchMemo/apps/companion/WatchMemo/AudioPlaybackController.swift`

- [ ] **Step 1: Add card list**

Show title, created time, duration, source, and status for each recording.

- [ ] **Step 2: Add playback controller**

Use `AVAudioPlayer` to play or pause a selected recording.

- [ ] **Step 3: Add simulator import button**

In Debug builds, add a toolbar button that imports the newest recording from the watch simulator container when available, or generates a tiny sample file if not.

- [ ] **Step 4: Build iOS target**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
```

Expected: pass.

### Task 4: Validate And Document Phase 3

**Files:**
- Create: `WatchMemo/docs/phase-logs/phase-3-phone-inbox-simulated-import.md`
- Modify: `WatchMemo/docs/current-status.md`
- Modify: `WatchMemo/docs/development.md`

- [ ] **Step 1: Run all local validations**

Run:

```bash
swift test --package-path WatchMemo/packages/PhoneInboxCore
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build
```

Expected: all pass.

- [ ] **Step 2: Document what is simulator-validated**

Record that iPhone inbox, metadata persistence, and playback UI build locally; real WatchConnectivity remains hardware-only.

- [ ] **Step 3: Commit**

Run:

```bash
git add WatchMemo
git commit -m "feat: add phone inbox simulated import"
```

Expected: commit succeeds.

## Self-Review

- Spec coverage: covers local inbox, simulated import, playback surface, reuse by WatchConnectivity, and documentation.
- Placeholder scan: no TBD/TODO placeholders remain.
- Type consistency: `InboxRecording`, `PhoneInboxStore`, `PhoneInboxViewModel`, and `AudioPlaybackController` are consistently named.
