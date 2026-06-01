# Phase 8 Log: Structured Notes and Markdown Copy

Date: 2026-06-01

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

## Pending Real-Device Validation

The user's iPhone and Apple Watch were away from the development environment
during this phase, so true-device validation is pending.

When devices are available again:

1. Install the updated iPhone app.
2. Install or refresh the updated Watch app.
3. Record a short phrase on Apple Watch.
4. Confirm the iPhone receives the recording.
5. Run AI processing.
6. Confirm the row shows a title/summary.
7. Tap `Copy Markdown`.
8. Paste into Notes or another text field and confirm the Markdown includes
   title, summary, body, and any extracted action items/tags.

## Remaining Risks

- The formatter is deterministic and conservative; it does not yet ask the model
  to return strict JSON.
- Action item and tag extraction only handles obvious `待办：` / `TODO:` and
  `标签：` / `Tags:` lines.
- Knowledge-base export is intentionally not implemented yet.
