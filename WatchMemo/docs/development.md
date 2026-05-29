# Development Notes

## Open The Companion Project

Project:

`WatchMemo/apps/companion/WatchMemo.xcodeproj`

Schemes:

- `WatchMemo`
- `WatchMemoWatch`

## Companion Command-Line Builds

Watch app:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS Simulator' \
  build
```

iPhone companion:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

If the iOS build reports that the iOS platform is not installed, install it
with:

```sh
xcodebuild -downloadPlatform iOS
```

Validated local platforms:

- watchOS 26.2 Simulator Runtime.
- iOS 26.3.1 Simulator Runtime downloaded through Xcode. The active SDK used by
  Xcode 26.2 for the build is iPhoneSimulator 26.2.

## Companion Debug Recording Self-Test

After building and installing the companion watch app to a booted watchOS
simulator:

```sh
SIMCTL_CHILD_WATCHMEMO_AUTOTEST_RECORDING=1 \
xcrun simctl launch --terminate-running-process \
  <WATCH_DEVICE_UDID> \
  com.watchmemo.app.watchkitapp
```

The app records briefly, stores audio under `Documents/Recordings/`, and writes
queue metadata to `Documents/recordings.json`.

## Open The watchOS Prototype

Project:

`WatchMemo/apps/watchos-prototype/WatchMemoWatch.xcodeproj`

Scheme:

`WatchMemoWatch`

## Command-Line Build

From the repository root:

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

Last known result:

- 2026-05-29: Build succeeded on Xcode 26.2.
- 2026-05-29: Build succeeded against Apple Watch Series 11 (46mm) watchOS 26.2
  simulator.

## Runtime Setup

The machine initially had watchOS SDK support but no installed Simulator
Runtime. Install it with:

```sh
xcodebuild -downloadPlatform watchOS
```

Validated runtime:

- watchOS 26.2, build 23S303.

## Debug Recording Self-Test

The prototype includes a Debug-only self-test entry point because automated
clicking inside the watchOS Simulator can be unreliable.

After installing the app to a booted simulator, launch with:

```sh
SIMCTL_CHILD_WATCHMEMO_AUTOTEST_RECORDING=1 \
xcrun simctl launch --terminate-running-process \
  <WATCH_DEVICE_UDID> \
  com.watchmemo.prototype.watch
```

The app automatically records for about 3 seconds, stops, and saves a local
`.m4a` file in its Documents directory.

To inspect the data container:

```sh
xcrun simctl get_app_container \
  <WATCH_DEVICE_UDID> \
  com.watchmemo.prototype.watch \
  data
```

Then look under `Documents/`.

## Manual Validation Needed

The command-line build validates the project and Swift code, but it does not
prove real recording behavior.

Phase 1 still needs manual validation in Xcode:

1. Open the project.
2. Select a watchOS simulator or real Apple Watch.
3. Run the `WatchMemoWatch` scheme.
4. Grant microphone permission.
5. Tap the microphone button.
6. Confirm the status changes to recording and elapsed time increases.
7. Tap stop.
8. Confirm no crash and document whether a playable `.m4a` file was created.

Real Apple Watch testing is preferred before Phase 1 is considered fully done.

Latest automated validation:

- Microphone prompt appeared on watchOS Simulator.
- Permission was granted.
- Debug self-test recorded for about 3 seconds.
- `.m4a` file was created in the app Documents directory.
- `afinfo` recognized it as mono AAC, 16 kHz, estimated duration 3.068 seconds.
