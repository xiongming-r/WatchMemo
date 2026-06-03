# Import Acknowledgement Design

Date: 2026-06-03

## Goal

Make Watch delivery state reflect iPhone persistence, not only
WatchConnectivity file-transfer completion.

## Problem

The Watch app currently marks a recording as `transferredToPhone` when
`WCSessionFileTransfer.didFinish` succeeds. That only proves WatchConnectivity
accepted and delivered the file transfer. It does not prove the iPhone app
copied the file into `PhoneInboxStore` and persisted its manifest.

Phase 12 fixed the immediate missing temporary file race on the iPhone, but the
Watch still needs a stronger acknowledgement boundary.

## Design

Use a tiny WatchConnectivity user-info message sent from iPhone to Watch after
successful iPhone import:

```text
type: watchmemo.importAcknowledged
recordingID: <UUID string>
```

The iPhone enqueues this message with `transferUserInfo` only after
`PhoneInboxStore.importRecording` returns successfully. `transferUserInfo` is
preferred over `sendMessage` because it can be delivered later when the Watch is
not immediately reachable. The Watch receives the message and marks the
matching recording as `transferredToPhone`.

The Watch file-transfer completion callback will no longer mark success. It
will only mark failure when WatchConnectivity reports an error. On successful
file-transfer completion it leaves the recording in `sendingToPhone` while it
waits for the iPhone import acknowledgement.

## Components

- `ImportAcknowledgementMessage`: pure Swift parser/builder for the user-info
  dictionary.
- `PhoneConnectivityReceiver`: sends the acknowledgement after importing.
- `IPhoneRelayTransport`: receives acknowledgement messages on Watch.
- `RecorderViewModel`: updates local manifest when acknowledgement arrives.

## Error Handling

- If iPhone import fails, no acknowledgement is sent.
- If acknowledgement message parsing fails on Watch, it is ignored.
- If WatchConnectivity file transfer fails, the Watch marks the recording
  `failed` as it does today.
- If file transfer succeeds but acknowledgement never arrives, the recording
  remains `sendingToPhone`; later phases can surface this as a retryable or
  diagnostic state.

## Out Of Scope

- Chunked recording upload.
- Background retry timers.
- iPhone-to-Watch detailed import error messages.
- Deleting Watch local audio after acknowledgement.

## Validation

- Unit tests cover message building and parsing.
- iOS Simulator app build passes.
- Real iPhone build/install/launch passes.
- Real Watch build/install/launch passes.
- True-device validation: record on Watch and confirm iPhone receives the
  recording. Watch should report final transfer success only after iPhone import
  acknowledgement.
