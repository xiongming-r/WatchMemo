# Import Acknowledgement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mark Watch recordings as transferred only after the iPhone imports and persists them.

**Architecture:** Add a small tested message builder/parser and matching app-side message types. The iPhone enqueues an acknowledgement user-info message after successful inbox import; the Watch receives it and updates its manifest.

**Tech Stack:** Swift, WatchConnectivity, Swift Testing, Xcode command-line builds.

---

### Task 1: Message Protocol

**Files:**
- Create: `WatchMemo/packages/WatchMemoMessageCore/Package.swift`
- Create: `WatchMemo/packages/WatchMemoMessageCore/Sources/WatchMemoMessageCore/WatchMemoMessageCore.swift`
- Create: `WatchMemo/packages/WatchMemoMessageCore/Tests/WatchMemoMessageCoreTests/ImportAcknowledgementMessageTests.swift`

- [ ] **Step 1: Write failing parser and builder tests**

```swift
import Foundation
import Testing
@testable import WatchMemoMessageCore

@Suite("Import acknowledgement message")
struct ImportAcknowledgementMessageTests {
    @Test("builds a WatchConnectivity-safe dictionary")
    func buildsDictionary() throws {
        let id = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))

        let dictionary = ImportAcknowledgementMessage(recordingID: id).dictionary

        #expect(dictionary["type"] as? String == "watchmemo.importAcknowledged")
        #expect(dictionary["recordingID"] as? String == id.uuidString)
    }

    @Test("parses a valid acknowledgement dictionary")
    func parsesDictionary() throws {
        let id = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))

        let message = ImportAcknowledgementMessage(dictionary: [
            "type": "watchmemo.importAcknowledged",
            "recordingID": id.uuidString
        ])

        #expect(message?.recordingID == id)
    }

    @Test("rejects invalid acknowledgement dictionaries")
    func rejectsInvalidDictionary() {
        #expect(ImportAcknowledgementMessage(dictionary: ["type": "other"]) == nil)
        #expect(ImportAcknowledgementMessage(dictionary: [
            "type": "watchmemo.importAcknowledged",
            "recordingID": "not-a-uuid"
        ]) == nil)
    }
}
```

- [ ] **Step 2: Verify tests fail**

Run: `swift test --package-path WatchMemo/packages/WatchMemoMessageCore`

Expected: fail because the package or type is not implemented yet.

- [ ] **Step 3: Implement the message type in the package and app shared file**

```swift
import Foundation

struct ImportAcknowledgementMessage: Equatable {
    static let messageType = "watchmemo.importAcknowledged"

    let recordingID: UUID

    var dictionary: [String: Any] {
        [
            "type": Self.messageType,
            "recordingID": recordingID.uuidString
        ]
    }

    init(recordingID: UUID) {
        self.recordingID = recordingID
    }

    init?(dictionary: [String: Any]) {
        guard dictionary["type"] as? String == Self.messageType,
              let idString = dictionary["recordingID"] as? String,
              let recordingID = UUID(uuidString: idString) else {
            return nil
        }

        self.recordingID = recordingID
    }
}
```

- [ ] **Step 4: Verify tests pass**

Run: `swift test --package-path WatchMemo/packages/WatchMemoMessageCore`

Expected: all tests pass.

### Task 2: iPhone Sends Acknowledgement

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneConnectivityReceiver.swift`

- [ ] **Step 1: After successful import, send acknowledgement**

Use `WCSession.default.transferUserInfo(_:)` with
`ImportAcknowledgementMessage(recordingID: imported.id).dictionary`.

- [ ] **Step 2: Build iOS Simulator app**

Run: `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoImportAckSimDerivedData build`

Expected: `BUILD SUCCEEDED`.

### Task 3: Watch Receives Acknowledgement

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemoWatch/IPhoneRelayTransport.swift`
- Modify: `WatchMemo/apps/companion/WatchMemoWatch/RecorderViewModel.swift`

- [ ] **Step 1: Add `onImportAcknowledged` callback to transport**

Parse incoming `didReceiveUserInfo` dictionaries with
`ImportAcknowledgementMessage(dictionary:)`.

- [ ] **Step 2: Update `RecorderViewModel` on acknowledgement**

Set matching recording state to `transferredToPhone` and show
`Transferred to iPhone`.

- [ ] **Step 3: Change successful file-transfer finish behavior**

On `didFinish fileTransfer` without an error, keep state as `sendingToPhone`
and show a waiting-for-import message.

- [ ] **Step 4: Build real devices**

Run: `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoImportAckDeviceDerivedData build`

Expected: `BUILD SUCCEEDED`.

### Task 4: Docs, Install, Commit

**Files:**
- Modify: `WatchMemo/docs/current-status.md`
- Create: `WatchMemo/docs/phase-logs/phase-13-import-acknowledgement.md`

- [ ] **Step 1: Record Phase 13 notes**

Document the new acknowledgement boundary and true-device test instructions.

- [ ] **Step 2: Install and launch real-device builds**

Install iPhone and Watch apps from
`/private/tmp/WatchMemoImportAckDeviceDerivedData/Build/Products`.

- [ ] **Step 3: Commit**

```bash
git add WatchMemo/apps/companion/WatchMemo/PhoneConnectivityReceiver.swift \
  WatchMemo/apps/companion/WatchMemoWatch/IPhoneRelayTransport.swift \
  WatchMemo/apps/companion/WatchMemoWatch/RecorderViewModel.swift \
  WatchMemo/packages/WatchMemoMessageCore \
  WatchMemo/docs/current-status.md \
  WatchMemo/docs/phase-logs/phase-13-import-acknowledgement.md \
  WatchMemo/docs/superpowers/specs/2026-06-03-import-acknowledgement-design.md \
  WatchMemo/docs/superpowers/plans/2026-06-03-import-acknowledgement.md
git commit -m "feat: acknowledge iphone recording imports"
```
