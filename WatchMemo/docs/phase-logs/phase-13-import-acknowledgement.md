# Phase 13 Log: iPhone Import Acknowledgement

Date: 2026-06-03

## Goal

Make the Watch-side `transferredToPhone` state mean that the iPhone has
imported and persisted the recording, not only that WatchConnectivity finished
the file transfer.

## Why This Phase

Phase 12 fixed the iPhone receive race by staging WatchConnectivity temporary
files immediately. The next reliability gap was semantic: WatchConnectivity
transfer completion does not prove the iPhone app saved the recording.

For long recordings, this distinction matters because the Watch should not
report final success until the iPhone inbox has the file and manifest entry.

## What Changed

- Added `WatchMemoMessageCore` with tests for the import acknowledgement
  dictionary.
- The iPhone now enqueues an acknowledgement with `transferUserInfo` after
  `PhoneInboxStore.importRecording` succeeds.
- The Watch transport receives acknowledgement user-info dictionaries and
  forwards the recording ID to `RecorderViewModel`.
- The Watch now leaves successful file-transfer completions in
  `sendingToPhone` and waits for the iPhone import acknowledgement before
  marking `transferredToPhone`.

## Message Shape

```text
type: watchmemo.importAcknowledged
recordingID: <UUID string>
```

`transferUserInfo` is used instead of `sendMessage` because the acknowledgement
should be queued for delivery if the Watch is not immediately reachable.

## Out Of Scope

- Watch local audio deletion after import acknowledgement.
- Retrying recordings stuck in `sendingToPhone`.
- Sending detailed iPhone import failures back to Watch.
- Chunked long-recording transfer.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
```

Result:

- 3 tests passed.
- Tests cover acknowledgement dictionary building, valid parsing, and invalid
  dictionary rejection.

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Result:

- 7 tests passed.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WatchMemoImportAckSimDerivedData \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoImportAckDeviceDerivedData \
  build
```

## True-Device Test

After install:

- Open iPhone WatchMemo and Apple Watch WatchMemo.
- Record a short clip on Watch.
- Confirm the iPhone receives the recording.
- Confirm the Watch reaches the final "Transferred to iPhone" state after the
  iPhone import acknowledgement.
