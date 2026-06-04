# Phase 21A: iPhone Fullscreen Compatibility

Date: 2026-06-04

## Goal

Fix the real-iPhone visual issue where the Stitch-inspired iPhone UI rendered
inside a centered, letterboxed rectangle with black space above and below.

## Findings

- The real-device screenshot showed classic iOS compatibility scaling:
  the app was centered instead of filling the screen, with oversized controls
  and large black top/bottom areas.
- The generated iPhone app `Info.plist` did not contain a launch screen key.
- The companion project uses generated Info.plist settings and had no
  `LaunchScreen.storyboard`.
- Apple launch-screen guidance treats a launch screen as the supported way to
  declare the app's initial full-screen geometry on modern iPhones.

References:

- https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen/
- https://developer.apple.com/documentation/bundleresources/information-property-list/uilaunchscreen
- https://developer.apple.com/documentation/technotes/tn3118-debugging-your-apps-launch-screen
- https://developer.apple.com/design/human-interface-guidelines/layout

## Implemented

- Added `LaunchScreen.storyboard` to the iPhone companion app target.
- Added `INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen` for the iPhone
  target's Debug and Release build settings.
- Kept the launch screen visually minimal and dark so it matches the app shell.
- Reduced the Stitch-inspired iPhone UI density where it was too large on a
  physical iPhone:
  - smaller app title,
  - tighter header actions,
  - more compact status strip and filter control,
  - smaller recording card title/padding,
  - smaller floating mic button,
  - tighter bottom navigation.

## Validation

- iOS Simulator build passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoLaunchFixSimDerivedData build
```

- Simulator app bundle validation confirmed:

```text
UILaunchStoryboardName => LaunchScreen
```

- Generic iOS device build passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoLaunchFixDeviceDerivedData build
```

- Device app bundle validation confirmed:

```text
UILaunchStoryboardName => LaunchScreen
LaunchScreen.storyboardc
```

- Core package regressions passed:
  - `TranscriptPipelineCore`: 16 tests.
  - `PhoneInboxCore`: 7 tests.
  - `NoteDeliveryCore`: 4 tests.
  - `WatchDeliveryCore`: 2 tests.
  - `WatchMemoMessageCore`: 3 tests.
  - `LongAudioProcessingCore`: 4 tests.

## Device Install Status

On 2026-06-04 10:16 Asia/Shanghai, the concrete iPhone destination build
passed and the app installed/launched on the real iPhone:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoLaunchFixConcreteDeviceDerivedData build
xcrun devicectl device install app --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 /private/tmp/WatchMemoLaunchFixConcreteDeviceDerivedData/Build/Products/Debug-iphoneos/WatchMemo.app
xcrun devicectl device process launch --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 com.watchmemo.app
```

The same build's Watch app also installed/launched on the paired Apple Watch:

```sh
xcrun devicectl device install app --device F855C270-A659-55F0-B2DE-9DDC98147813 /private/tmp/WatchMemoLaunchFixConcreteDeviceDerivedData/Build/Products/Debug-watchos/WatchMemoWatch.app
xcrun devicectl device process launch --device F855C270-A659-55F0-B2DE-9DDC98147813 com.watchmemo.app.watchkitapp
```

If black bars persist after a normal install, uninstalling and reinstalling may
be required because iOS can cache launch screen data. That will reset local app
data, so it should only be done intentionally.
