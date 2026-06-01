# Phase 7 Real API Device Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable real OpenAI-compatible transcription from the iPhone app while keeping API keys out of source control and making true completion depend on real-device validation.

**Architecture:** Add provider settings UI in the iPhone app, save non-secret provider settings in `UserDefaults`, save API key in Keychain, and build the transcript pipeline dynamically from those settings. Keep fake provider as the safe default.

**Tech Stack:** SwiftUI, Security.framework Keychain APIs, UserDefaults JSON persistence, existing `TranscriptPipelineCore`, Xcode companion project.

---

### Task 1: Provider Settings Model

**Files:**
- Create: `WatchMemo/packages/TranscriptPipelineCore/Sources/TranscriptPipelineCore/ProviderRuntimeSettings.swift`
- Modify: `WatchMemo/packages/TranscriptPipelineCore/Tests/TranscriptPipelineCoreTests/TranscriptPipelineTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests proving default settings are fake and OpenAI-compatible settings carry endpoint/model.

- [ ] **Step 2: Run red**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

- [ ] **Step 3: Implement settings model**

Create `ProviderRuntimeSettings` as Codable, Equatable, Sendable with default fake settings and an OpenAI-compatible factory.

- [ ] **Step 4: Run green**

Run the same package test and expect PASS.

### Task 2: iPhone Settings And Keychain

**Files:**
- Create: `WatchMemo/apps/companion/WatchMemo/APIKeyStore.swift`
- Create: `WatchMemo/apps/companion/WatchMemo/ProviderSettingsStore.swift`
- Create: `WatchMemo/apps/companion/WatchMemo/ProviderSettingsView.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/PhoneInboxViewModel.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo/ContentView.swift`
- Modify: `WatchMemo/apps/companion/WatchMemo.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add Keychain API key store**

Use Security.framework. Store only the API key in Keychain.

- [ ] **Step 2: Add UserDefaults settings store**

Persist provider selection, endpoint URL, and model.

- [ ] **Step 3: Add settings UI**

Add a toolbar settings button. The sheet lets the user choose Fake or
OpenAI-compatible, edit endpoint/model, enter API key, save, and see key status.

- [ ] **Step 4: Build provider dynamically**

`PhoneInboxViewModel` uses fake provider unless settings select OpenAI-compatible
and a Keychain API key is present.

### Task 3: Verification, Device Checklist, Commit

**Files:**
- Create: `WatchMemo/docs/phase-logs/phase-7-real-api-device-validation.md`
- Modify: `WatchMemo/docs/current-status.md`
- Modify: `WatchMemo/docs/development.md`

- [ ] **Step 1: Run local verification**

Run:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
swift test --package-path WatchMemo/packages/PhoneInboxCore
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build
```

- [ ] **Step 2: Document real-device checklist**

Record that Phase 7 is only complete after the user validates on real iPhone +
Apple Watch.

- [ ] **Step 3: Commit**

Commit as:

```sh
git commit -m "feat: enable real api provider settings"
```
