# Phase 1: watchOS Recording Prototype

Date started: 2026-05-29

## Goal

Build the smallest possible watchOS app that proves Apple Watch can act as a
reliable capture surface.

## Scope

Required:

- Create a watchOS prototype app in Xcode. Done.
- Request microphone permission. Implemented, needs runtime validation.
- Start recording from the watch. Implemented, needs runtime validation.
- Stop recording from the watch. Implemented, needs runtime validation.
- Save the audio file locally. Implemented, needs runtime validation.
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

- The watch app can record and stop without crashing. Not yet validated.
- A recording file exists after stop. Not yet validated.
- The recording file can be played back or exported for validation. Not yet
  validated.
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

## Notes To Fill During Implementation

- Xcode version: 26.2, build 17C52.
- watchOS deployment target: watchOS 10.0.
- Tested on simulator: Build only. Runtime simulator launch not validated in
  sandbox.
- Tested on real Apple Watch: Not yet.
- Audio format: `.m4a` using MPEG-4 AAC, 16 kHz, mono, medium quality.
- Recording file path: app document directory, file name pattern
  `watchmemo-<ISO timestamp>.m4a`.
- Permission behavior: Implemented with `AVAudioSession.requestRecordPermission`,
  but runtime prompt behavior still needs validation.
- Lifecycle behavior: Not yet validated.
- Bugs or risks found: `#Preview` macro failed in sandbox; removed. Long-running
  recording, screen sleep, and background behavior still unknown.

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

## Next Manual Test

Open the project in Xcode, run the `WatchMemoWatch` scheme, and record what
happens for permission, start, stop, and saved file validation.
