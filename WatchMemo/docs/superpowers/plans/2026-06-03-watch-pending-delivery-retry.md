# Watch Pending Delivery Retry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Retry Watch recordings that are waiting for iPhone import acknowledgement when the Watch delivery queue prepares.

**Architecture:** Add a tested pure Swift retry policy, then apply the same policy in `DeliveryQueue.retryPending()`. Keep the app behavior minimal: no timers, no local deletion, no retry counters.

**Tech Stack:** Swift, Swift Testing, WatchConnectivity, Xcode command-line builds.

---

### Task 1: Retry Policy Tests

**Files:**
- Create: `WatchMemo/packages/WatchDeliveryCore/Package.swift`
- Create: `WatchMemo/packages/WatchDeliveryCore/Sources/WatchDeliveryCore/WatchDeliveryCore.swift`
- Create: `WatchMemo/packages/WatchDeliveryCore/Tests/WatchDeliveryCoreTests/DeliveryRetryPolicyTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
@testable import WatchDeliveryCore

@Suite("Delivery retry policy")
struct DeliveryRetryPolicyTests {
    @Test("retries states that still need an iPhone import acknowledgement")
    func retriesUnconfirmedStates() {
        #expect(DeliveryRetryPolicy.shouldRetry(.recorded))
        #expect(DeliveryRetryPolicy.shouldRetry(.sendingToPhone))
        #expect(DeliveryRetryPolicy.shouldRetry(.failed))
    }

    @Test("does not retry recordings already acknowledged by iPhone import")
    func doesNotRetryAcknowledgedState() {
        #expect(!DeliveryRetryPolicy.shouldRetry(.transferredToPhone))
    }
}
```

- [ ] **Step 2: Verify tests fail**

Run: `swift test --package-path WatchMemo/packages/WatchDeliveryCore`

Expected: fail because `DeliveryRetryPolicy` does not exist.

- [ ] **Step 3: Implement minimal policy**

```swift
public enum DeliveryState: String, Codable, Equatable {
    case recorded
    case sendingToPhone
    case transferredToPhone
    case failed
}

public enum DeliveryRetryPolicy {
    public static func shouldRetry(_ state: DeliveryState) -> Bool {
        switch state {
        case .recorded, .sendingToPhone, .failed:
            return true
        case .transferredToPhone:
            return false
        }
    }
}
```

- [ ] **Step 4: Verify tests pass**

Run: `swift test --package-path WatchMemo/packages/WatchDeliveryCore`

Expected: all tests pass.

### Task 2: Apply Policy In Watch Delivery Queue

**Files:**
- Modify: `WatchMemo/apps/companion/WatchMemoWatch/DeliveryQueue.swift`

- [ ] **Step 1: Add app-side retry predicate**

```swift
private func shouldRetry(_ state: RecordingManifest.DeliveryState) -> Bool {
    switch state {
    case .recorded, .sendingToPhone, .failed:
        return true
    case .transferredToPhone:
        return false
    }
}
```

- [ ] **Step 2: Use predicate in `retryPending()`**

Change the loop condition to retry any state accepted by `shouldRetry`.

- [ ] **Step 3: Build simulator**

Run: `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPendingRetrySimDerivedData build`

Expected: `BUILD SUCCEEDED`.

### Task 3: Docs, Device Install, Commit

**Files:**
- Modify: `WatchMemo/docs/current-status.md`
- Create: `WatchMemo/docs/phase-logs/phase-14-watch-pending-delivery-retry.md`

- [ ] **Step 1: Document Phase 14**

Record the retry policy, validation commands, and true-device test guidance.

- [ ] **Step 2: Build and install real devices**

Run the real iPhone destination build, install the iPhone app, install the
Watch app, and launch both apps.

- [ ] **Step 3: Commit**

```bash
git add WatchMemo/apps/companion/WatchMemoWatch/DeliveryQueue.swift \
  WatchMemo/packages/WatchDeliveryCore \
  WatchMemo/docs/current-status.md \
  WatchMemo/docs/phase-logs/phase-14-watch-pending-delivery-retry.md \
  WatchMemo/docs/superpowers/specs/2026-06-03-watch-pending-delivery-retry-design.md \
  WatchMemo/docs/superpowers/plans/2026-06-03-watch-pending-delivery-retry.md
git commit -m "feat: retry unacknowledged watch deliveries"
```
