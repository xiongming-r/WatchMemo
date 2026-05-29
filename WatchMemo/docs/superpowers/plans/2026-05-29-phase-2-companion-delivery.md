# Phase 2 Companion Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first iOS + watchOS companion app foundation and move watch recordings into a local delivery queue that can later support iPhone relay, direct cloud upload, and knowledge-base export.

**Architecture:** Keep the watch app as the capture surface. Save every recording locally through `LocalRecordingStore`, register it in `DeliveryQueue`, then attempt delivery through a transport boundary. The first concrete transport is `IPhoneRelayTransport` backed by WatchConnectivity.

**Tech Stack:** Swift, SwiftUI, AVFoundation, WatchConnectivity, Xcode 26.2, watchOS 26.2 simulator.

---

### Task 1: Create Companion Project Skeleton

**Files:**
- Create: `WatchMemo/apps/companion/WatchMemo.xcodeproj/project.pbxproj`
- Create: `WatchMemo/apps/companion/WatchMemo/WatchMemoApp.swift`
- Create: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`
- Create: `WatchMemo/apps/companion/WatchMemoWatch/WatchMemoWatchApp.swift`
- Create: `WatchMemo/apps/companion/WatchMemoWatch/ContentView.swift`

- [ ] **Step 1: Add an iOS app target and watchOS app target**

Create a minimal Xcode project with two targets:

- `WatchMemo`, bundle id `com.watchmemo.app`, SDK `iphoneos`.
- `WatchMemoWatch`, bundle id `com.watchmemo.app.watchkitapp`, SDK `watchos`, companion id `com.watchmemo.app`.

- [ ] **Step 2: Add placeholder SwiftUI apps**

iOS starts with a recording inbox placeholder. Watch starts with a one-button placeholder before recorder migration.

- [ ] **Step 3: Build both schemes**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build
```

Expected: both commands finish with `** BUILD SUCCEEDED **`.

### Task 2: Add Recording Store And Delivery Queue

**Files:**
- Create: `WatchMemo/apps/companion/WatchMemoWatch/RecordingManifest.swift`
- Create: `WatchMemo/apps/companion/WatchMemoWatch/LocalRecordingStore.swift`
- Create: `WatchMemo/apps/companion/WatchMemoWatch/DeliveryQueue.swift`

- [ ] **Step 1: Define recording metadata**

`RecordingManifest` stores id, file name, created date, duration, delivery state, and optional error message.

- [ ] **Step 2: Persist queue metadata**

`LocalRecordingStore` stores audio in Documents and persists manifests as JSON so app relaunches do not lose unsent recordings.

- [ ] **Step 3: Add a delivery transport protocol**

`RecordingDeliveryTransport` defines `send(recording:) async throws`.

- [ ] **Step 4: Run a watch build**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build
```

Expected: `** BUILD SUCCEEDED **`.

### Task 3: Migrate Recorder Into Companion Watch App

**Files:**
- Create: `WatchMemo/apps/companion/WatchMemoWatch/RecorderViewModel.swift`
- Modify: `WatchMemo/apps/companion/WatchMemoWatch/ContentView.swift`

- [ ] **Step 1: Port the validated recorder**

Move the Phase 1 AVFoundation recorder into the companion watch target, keeping the debug autotest environment variable `WATCHMEMO_AUTOTEST_RECORDING=1`.

- [ ] **Step 2: Save through `LocalRecordingStore`**

When recording stops, compute the duration and write a manifest into the local queue.

- [ ] **Step 3: Show delivery state on watch**

Display a short status message such as `Queued locally`, `Sending to iPhone`, or `Saved locally`.

- [ ] **Step 4: Build and run autotest**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build
env SIMCTL_CHILD_WATCHMEMO_AUTOTEST_RECORDING=1 xcrun simctl launch --terminate-running-process AAA54981-8966-488C-86A9-C3F5E211850F com.watchmemo.app.watchkitapp
```

Expected: app launches and records a short `.m4a` file.

### Task 4: Add WatchConnectivity Relay Stub

**Files:**
- Create: `WatchMemo/apps/companion/WatchMemoWatch/IPhoneRelayTransport.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`
- Create: `WatchMemo/apps/companion/WatchMemo/PhoneConnectivityReceiver.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/WatchMemoApp.swift`

- [ ] **Step 1: Add watch sender**

On watchOS, activate `WCSession` and call `transferFile(_:metadata:)` for queued recordings when supported.

- [ ] **Step 2: Add iPhone receiver**

On iOS, activate `WCSession`, receive files through `session(_:didReceive:)`, and show a simple received-count inbox.

- [ ] **Step 3: Document simulator limitation**

Record that Apple does not support full `transferFile` validation in simulator, so hardware validation is required.

- [ ] **Step 4: Build both schemes**

Run:

```bash
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build
```

Expected: both commands finish with `** BUILD SUCCEEDED **`.

### Task 5: Update Phase Documentation

**Files:**
- Create: `WatchMemo/docs/phase-logs/phase-2-companion-delivery.md`
- Modify: `WatchMemo/docs/current-status.md`
- Modify: `WatchMemo/docs/development.md`

- [ ] **Step 1: Record what works**

Document build status, simulator status, and hardware-only validation gaps.

- [ ] **Step 2: Commit**

Run:

```bash
git add WatchMemo/apps/companion WatchMemo/docs
git commit -m "feat: add companion delivery foundation"
```

Expected: commit succeeds.

## Self-Review

- Spec coverage: covers companion skeleton, local queue, transport boundary, WatchConnectivity first path, and phase documentation.
- Placeholder scan: no TBD/TODO placeholders remain.
- Type consistency: `LocalRecordingStore`, `DeliveryQueue`, `RecordingManifest`, `RecordingDeliveryTransport`, and `IPhoneRelayTransport` names are stable across tasks.
