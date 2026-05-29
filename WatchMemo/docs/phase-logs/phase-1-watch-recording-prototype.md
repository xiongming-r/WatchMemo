# Phase 1: watchOS Recording Prototype

Date started: 2026-05-29

## Goal

Build the smallest possible watchOS app that proves Apple Watch can act as a
reliable capture surface.

## Scope

Required:

- Create a watchOS prototype app in Xcode. Done.
- Request microphone permission. Validated on watchOS Simulator.
- Start recording from the watch. Validated through Debug self-test.
- Stop recording from the watch. Validated through Debug self-test.
- Save the audio file locally. Validated through Debug self-test.
- Show recording, idle, and error states. Implemented.

Optional:

- Pause and resume.
- Show elapsed time.
- Add one quick tag.

Out of scope:

- iPhone transfer.
- Transcription.
- Summary generation.
- Cloud upload.
- Multi-platform support.

## Completion Criteria

Phase 1 is complete when:

- The watch app can record and stop without crashing. Validated through Debug
  self-test on watchOS Simulator.
- A recording file exists after stop. Validated.
- The recording file can be played back or exported for validation. File format
  validated with `afinfo`; playback still needs manual listening.
- Known limitations are documented in this file. In progress.

## Work Log

- 2026-05-29: Created a standalone watchOS SwiftUI prototype project at
  `apps/watchos-prototype/WatchMemoWatch.xcodeproj`.
- 2026-05-29: Implemented a single-screen watch UI with ready/recording status,
  elapsed time, and one button for start/stop.
- 2026-05-29: Implemented microphone permission request, `AVAudioRecorder`
  setup, local `.m4a` file naming, timer state, and basic error handling.
- 2026-05-29: Removed `#Preview` from the watch view because the preview macro
  plugin failed inside the command-line sandbox.
- 2026-05-29: Command-line build succeeded with Xcode 26.2 using the
  watchOS 26.2 simulator SDK.
- 2026-05-29: Installed watchOS 26.2 Simulator Runtime with
  `xcodebuild -downloadPlatform watchOS`.
- 2026-05-29: Booted Apple Watch Series 11 (46mm) simulator
  `AAA54981-8966-488C-86A9-C3F5E211850F`.
- 2026-05-29: Initial install failed because the hand-written target was
  missing `WKCompanionAppBundleIdentifier`; added the required generated
  Info.plist key.
- 2026-05-29: Tried changing the target product type to
  `com.apple.product-type.application.watchapp2`, but the hand-written project
  then produced duplicate executable build outputs. Reverted to the previously
  buildable target shape and kept the Info.plist key. Phase 2 should use a
  standard Xcode-generated iOS + watchOS project.
- 2026-05-29: Added a Debug-only recording self-test launched via
  `WATCHMEMO_AUTOTEST_RECORDING=1`, because automated clicking inside the
  simulator was unreliable.
- 2026-05-29: Debug self-test launched successfully, recorded for about 3
  seconds, stopped, and saved `.m4a` files in the watch app Documents directory.
- 2026-05-29: Updated microphone permission request to
  `AVAudioApplication.requestRecordPermission`.

## Notes To Fill During Implementation

- Xcode version: 26.2, build 17C52.
- watchOS deployment target: watchOS 10.0.
- Tested on simulator: Apple Watch Series 11 (46mm), watchOS 26.2. Automated
  Debug self-test validated permission, recording, stop, and save behavior.
- Tested on real Apple Watch: Not yet.
- Audio format: `.m4a` using MPEG-4 AAC, 16 kHz, mono, medium quality.
- Recording file path: app document directory, file name pattern
  `watchmemo-<ISO timestamp>.m4a`.
- Permission behavior: Runtime prompt appeared in the watchOS Simulator and was
  granted. Later launches can also be granted with `simctl privacy`.
- Lifecycle behavior: Short foreground recording validated. Long-running,
  screen sleep, background, and interruption behavior not yet validated.
- Bugs or risks found: `#Preview` macro failed in sandbox; removed. Automated
  GUI clicking inside the Simulator was unreliable. Long-running recording,
  screen sleep, and background behavior still unknown.

## Validation

Command:

```sh
xcodebuild \
  -project WatchMemo/apps/watchos-prototype/WatchMemoWatch.xcodeproj \
  -scheme WatchMemoWatch \
  -configuration Debug \
  -sdk watchsimulator26.2 \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath WatchMemo/build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Result:

- Build succeeded on 2026-05-29.

Runtime setup:

```sh
xcodebuild -downloadPlatform watchOS
```

Result:

- Installed watchOS 26.2 Simulator Runtime, build 23S303.

Debug self-test command:

```sh
SIMCTL_CHILD_WATCHMEMO_AUTOTEST_RECORDING=1 \
xcrun simctl launch --terminate-running-process \
  AAA54981-8966-488C-86A9-C3F5E211850F \
  com.watchmemo.prototype.watch
```

Result:

- App launched with process id `63593`.
- UI returned to Ready and displayed `Autotest recording saved`.
- Screenshot saved at `WatchMemo/build/watch-simulator-autotest.png`.
- Latest validated file:
  `watchmemo-2026-05-29T09-22-48Z.m4a`, 24 KB.
- `afinfo` recognized the file as mono AAC, 16 kHz, estimated duration
  3.068 seconds.

## Next Manual Test

Open the project in Xcode or run on a real Apple Watch, tap the button manually,
and record what happens for start, stop, saved file validation, screen sleep,
and longer recordings.

Phase 2 should replace the hand-written standalone watch project with a
standard iOS + watchOS companion project before implementing Watch
Connectivity.
