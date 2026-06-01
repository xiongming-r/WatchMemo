# Phase 7 Log: Real API Provider Settings, Pending Device Validation

Date: 2026-06-01

## Goal

Enable the iPhone app to use a real OpenAI-compatible transcription API while
keeping the API key out of source control. Confirm the full real-device loop:
Apple Watch recording, iPhone receipt, and AI-generated text.

## What Changed

- Added `ProviderRuntimeSettings` to `TranscriptPipelineCore`.
- Added tests for default fake provider settings and OpenAI-compatible runtime
  settings.
- Added `APIKeyStore`, backed by Keychain.
- Added `ProviderSettingsStore`, backed by `UserDefaults`, for non-secret
  provider settings.
- Added `ProviderSettingsView`, opened from the iPhone app toolbar.
- Updated `PhoneInboxViewModel` to build the transcript pipeline dynamically:
  - Fake provider remains the default.
  - OpenAI-compatible provider is used only when selected and an API key exists.
- Added localized provider error messages for better true-device debugging.

## Local Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS Simulator' \
  build
```

Blocked for device signing:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS' \
  build
```

Result:

- `Signing for "WatchMemo" requires a development team.`
- This must be resolved in Xcode by selecting a Development Team for real-device
  builds.

## Real-Device Validation Checklist

Phase 7 is complete only after the user confirms:

1. Xcode signing is configured for the iPhone app target.
2. The app installs and launches on a real iPhone.
3. Provider settings opens from the gear button.
4. The user selects `OpenAI-compatible`.
5. Endpoint is `https://api.openai.com/v1` or another compatible endpoint.
6. Model is `gpt-4o-transcribe` or another compatible transcription model.
7. API key is saved, and the screen reports saved state.
8. A real or Debug-imported recording appears in the iPhone inbox.
9. Tapping the sparkle button sends a real transcription request.
10. A transcript draft appears and is persisted after app restart.

Apple Watch end-to-end validation should additionally confirm:

1. A recording is captured on the real Apple Watch.
2. The recording transfers to the iPhone app inbox.
3. The transferred recording can be transcribed through the real provider.

## Current Status

Complete.

The Mac and Xcode toolchain are now compatible with the user's real devices:

- `macOS 26.5`
- `Xcode 26.5 (17F42)`
- `watchOS 26.5` SDK
- Apple Watch Series 10 on watchOS `26.5`

Fresh command-line validation after the upgrade:

- `xcodebuild -version` reports `Xcode 26.5`.
- `xcodebuild -showsdks` reports `watchOS 26.5`.
- `devicectl` reports the Apple Watch has developer mode enabled, DDI services
  available, and a connected tunnel.
- The iPhone app rebuilt, installed, and launched on the real iPhone:
  `com.watchmemo.app`.
- The Watch app rebuilt, installed, and launched on the real Apple Watch:
  `com.watchmemo.app.watchkitapp`.

Important signing note:

- Installing the first generic watchOS build failed with
  `This provisioning profile cannot be installed on this device`.
- Rebuilding the Watch target with the concrete destination
  `platform=watchOS,id=00008310-001479040C8B601E` generated a usable profile,
  and `devicectl device install app` then succeeded.

After the transfer fix below, the user confirmed the real-device MVP loop
succeeds:

- Apple Watch records audio.
- iPhone receives and displays the recording.
- The configured audio-understanding provider returns text successfully.

## 2026-06-01 Watch Transfer Debugging

The first real Watch recording test did not appear in the iPhone inbox.

Evidence collected from the devices:

- The Watch app did create local `.m4a` files in `Documents/Recordings`.
- The Watch app persisted two manifest entries in `Documents/recordings.json`.
- The WatchConnectivity internal `FileTransfers` directory contained two
  pending file-transfer records with state `transferring`.
- The iPhone app inbox still only contained earlier `simulatedImport` records.

Root-cause findings:

- The Watch app was incorrectly marking a recording as `transferredToPhone`
  immediately after `WCSession.transferFile(...)` returned. That API only means
  the file was accepted into the system transfer queue, not that the iPhone
  received it.
- The companion project had the iPhone and Watch targets as independent targets.
  The iPhone app did not embed `WatchMemoWatch.app`, so the installed iPhone
  app had no `Watch/WatchMemoWatch.app` bundle. This likely made
  WatchConnectivity pairing/installation state ambiguous for the iPhone side.

Fixes applied:

- Added an `Embed Watch Content` build phase to the iPhone target and an
  explicit dependency on the Watch target.
- Updated the Watch delivery flow so queued transfers stay in
  `sendingToPhone` until WatchConnectivity calls the file-transfer completion
  delegate.
- Added iPhone-side WatchConnectivity status text showing whether the phone is
  paired and whether the watch app is installed.

Fresh validation:

- A pre-fix check confirmed
  `/private/tmp/WatchMemoDerivedData/Build/Products/Debug-iphoneos/WatchMemo.app/Watch`
  did not exist.
- After the fix, the iPhone build copied
  `WatchMemoWatch.app` into `WatchMemo.app/Watch/WatchMemoWatch.app` and ran
  `ValidateEmbeddedBinary`.
- The rebuilt iPhone app installed/launched on the real iPhone.
- The rebuilt Watch app installed/launched on the real Apple Watch.

## Remaining Risks

- WatchConnectivity background behavior still needs longer-run validation,
  especially when the iPhone app is not foregrounded.
- The current UI is still a developer/debug surface rather than a polished note
  workflow.
- AI output is plain text only; it does not yet produce structured title,
  summary, action items, tags, or export-ready Markdown.
- The app does not yet export to Obsidian or another knowledge base.

## Next Candidate Phase

Recommended next phase:

- Stabilize the MVP loop before adding export integrations: make transfer
  status visible, add retry/manual resend affordances, and persist AI output in
  a note-oriented shape.

Alternative next phases:

- Build structured AI note output: title, cleaned transcript, summary, action
  items, tags, and Markdown.
- Start knowledge-base export: first local Markdown/Obsidian file export, later
  app-specific API integrations.
