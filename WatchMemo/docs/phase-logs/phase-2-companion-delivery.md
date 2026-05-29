# Phase 2: Companion Delivery Foundation

Date started: 2026-05-29
Date completed: 2026-05-29

## Goal

Create the first iOS + watchOS companion foundation and prove the watch app can
save recordings into a recoverable local delivery queue.

## Scope

Included:

- Create `apps/companion/WatchMemo.xcodeproj`.
- Add an iOS companion target for the future recording inbox.
- Add a watchOS target for quick recording.
- Move Phase 1 recorder behavior into the companion watch app.
- Add `LocalRecordingStore`, `RecordingManifest`, and `DeliveryQueue`.
- Add a first `IPhoneRelayTransport` wrapper around WatchConnectivity.
- Add a first iPhone `PhoneConnectivityReceiver`.

Excluded:

- Cloud upload.
- AI transcription.
- Markdown/Obsidian export.
- Real paired-device WatchConnectivity validation.
- Long recording battery/runtime testing.

## Completion Criteria

- watchOS companion target builds from the command line.
- watchOS debug autotest saves a local `.m4a` file.
- watchOS debug autotest writes a `recordings.json` manifest.
- iOS companion target builds from the command line once the iOS simulator
  platform is installed.
- Hardware validation requirements are documented.

## Work Log

- 2026-05-29: Created a new companion Xcode project under `apps/companion/`.
- 2026-05-29: Added minimal SwiftUI iOS and watchOS apps.
- 2026-05-29: Added local recording storage and queue metadata.
- 2026-05-29: Migrated the watch recorder from the Phase 1 prototype.
- 2026-05-29: Added WatchConnectivity sender/receiver stubs.
- 2026-05-29: Installed iOS Simulator platform with
  `xcodebuild -downloadPlatform iOS` because this machine had watchOS Simulator
  installed but not iOS Simulator.
- 2026-05-29: Validated both `WatchMemoWatch` and `WatchMemo` schemes with
  `xcodebuild`.

## Decisions Made

- Decision: Keep the new companion project separate from the Phase 1 prototype.
  Reason: Phase 1 remains a small proof point; Phase 2 needs different target
  structure and iPhone integration.

- Decision: Model transfer as `DeliveryQueue` plus `RecordingDeliveryTransport`.
  Reason: iPhone relay is the first reliability path, but future direct cloud
  upload should not require rewriting recording storage.

- Decision: Do not treat WatchConnectivity transfer failure as recording
  failure.
  Reason: Saving the original audio locally is the product trust boundary.
  Transfer can retry later.

## Risks Found

- Risk: `WCSession.transferFile` cannot be fully validated in simulator.
  Mitigation: Build the code path now, then validate on a real paired iPhone
  and Apple Watch.

- Risk: This machine initially lacked the iOS Simulator platform.
  Mitigation: Installed iOS Simulator and validated the iPhone companion target.

- Risk: The first simulator autotest wrote a very short audio file while
  CoreSimulator was unstable.
  Mitigation: Kept `afinfo` validation, fixed duration metadata to fall back to
  wall-clock time, and marked real-device validation as required.

## Validation

- Command/test/device: `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemoWatch -destination 'generic/platform=watchOS Simulator' build`
  Result: Passed.

- Command/test/device: Install and launch `com.watchmemo.app.watchkitapp` on
  Apple Watch Series 11 (46mm) simulator with
  `WATCHMEMO_AUTOTEST_RECORDING=1`.
  Result: App launched, saved `.m4a`, and wrote `recordings.json`.

- Command/test/device: `afinfo` on generated recording.
  Result: File is mono AAC, 16 kHz. First Phase 2 simulator run produced a very
  short file, so real-device validation remains required.

- Command/test/device: `xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' build`
  Result: Passed after installing iOS Simulator.

## Next Phase Notes

- Validate `transferFile` on physical paired devices.
- Add retry visibility on iPhone after real transfer behavior is observed.
