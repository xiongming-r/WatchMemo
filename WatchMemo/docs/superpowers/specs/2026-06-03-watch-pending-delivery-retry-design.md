# Watch Pending Delivery Retry Design

Date: 2026-06-03

## Goal

Prevent Watch recordings from staying forever in `sendingToPhone` when a file
transfer or import acknowledgement is interrupted.

## Problem

After Phase 13, `transferredToPhone` means the iPhone has imported and
persisted a recording. That is the right success boundary, but it introduces a
new recoverability case:

- Watch sends a file.
- WatchConnectivity reports file-transfer completion.
- iPhone imports the file.
- The import acknowledgement is delayed or missed.
- The Watch recording remains `sendingToPhone`.

The current retry pass only retries `recorded` and `failed`, so a
`sendingToPhone` recording can stay stuck until manually corrected.

## Design

Treat `sendingToPhone` as retryable when the Watch app prepares its delivery
queue. A retry re-sends the original local audio file with the same recording
ID. The iPhone inbox store already imports by recording ID, so a duplicate
delivery replaces the existing entry instead of creating a second note.

This phase does not add timers or background scheduling. It covers the most
important recovery moment: the next time the user opens or foregrounds the
Watch app and `prepare()` runs.

## Retry Policy

Retryable:

- `recorded`: saved locally but not sent.
- `sendingToPhone`: sent or in-flight, but no iPhone import acknowledgement yet.
- `failed`: previous send failed.

Not retryable:

- `transferredToPhone`: iPhone import acknowledgement was received.

## Components

- `WatchDeliveryCore`: tested pure Swift retry policy.
- `DeliveryQueue.retryPending()`: uses the same policy and includes
  `sendingToPhone`.

## Out Of Scope

- Time-based retry after 5 minutes while the Watch app stays active.
- Retry attempt counters.
- iPhone detailed failure acknowledgement.
- Watch local file deletion after confirmed import.
- Chunked long-recording transfer.

## Validation

- Unit tests cover the retry policy for every delivery state.
- iOS Simulator build passes.
- Real-device build/install/launch passes.
- True-device validation: after normal recording, iPhone should still receive
  and Watch should still reach final success. Recovery of a missed
  acknowledgement can be tested later by forcing or simulating a stuck
  `sendingToPhone` manifest.
