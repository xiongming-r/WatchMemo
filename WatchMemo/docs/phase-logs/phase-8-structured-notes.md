# Phase 8 Log: Structured Notes and Markdown Copy

Date: 2026-06-01

Status: Complete as of 2026-06-02 09:55 Asia/Shanghai

## Goal

Turn successful AI text output into a persisted note-oriented object that can be
reviewed on iPhone and copied as Markdown before adding knowledge-base export.

## What Changed

- Added `StructuredTranscriptNote` with:
  - `title`
  - `body`
  - `summary`
  - `actionItems`
  - `tags`
  - `markdown`
- Added `TranscriptNoteFormatter` to derive a stable note object from cleaned
  AI text.
- Updated `TranscriptPipeline` so every new `TranscriptDraft` includes a
  structured note.
- Kept old persisted drafts compatible by making `structuredNote` optional.
- Updated the iPhone inbox row to show a note-style preview:
  - title
  - summary
  - action items when present
- Added a row-level `Copy Markdown` action for generated notes.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Result:

- 12 tests passed.
- Tests cover note formatting, pipeline note attachment, and legacy draft
  decoding without `structuredNote`.

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Result:

- 4 tests passed.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WatchMemoPhase8DerivedData \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoPhase8DeviceDerivedData \
  build
```

Passed after rerunning separately with its own DerivedData path:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoPhase8iOSDeviceDerivedData \
  build
```

Note:

- A concurrent iOS/watchOS build attempt failed with a build database lock. This
  was an Xcode concurrency issue from sharing the same DerivedData path, not a
  product build failure.

## Real-Device Validation

Completed on 2026-06-02 with the user's real iPhone and Apple Watch.

Computer-side setup:

1. Built the iPhone app for the real iPhone destination:

   ```sh
   xcodebuild \
     -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
     -scheme WatchMemo \
     -destination id=00008130-000E61100E01001C \
     -allowProvisioningUpdates \
     -derivedDataPath /private/tmp/WatchMemoRealDevicePhase8 \
     build
   ```

2. The build succeeded.
3. Xcode ran `ValidateEmbeddedBinary` for
   `WatchMemo.app/Watch/WatchMemoWatch.app`, confirming the iPhone app embeds
   the Watch app correctly.
4. Installed and launched the iPhone app on the real iPhone.
5. Installed and launched the Watch app on the real Apple Watch.

User-side validation:

1. Recorded on Apple Watch.
2. Confirmed the iPhone received the recording.
3. Ran AI processing on the iPhone.
4. Confirmed structured note output appeared.
5. Confirmed Markdown copy is available.

Result:

- Phase 8 true-device validation passed.

## Remaining Risks

- The formatter is deterministic and conservative; it does not yet ask the model
  to return strict JSON.
- Action item and tag extraction only handles obvious `待办：` / `TODO:` and
  `标签：` / `Tags:` lines.
- Knowledge-base export is intentionally not implemented yet.
