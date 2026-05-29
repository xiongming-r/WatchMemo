# Development Notes

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

