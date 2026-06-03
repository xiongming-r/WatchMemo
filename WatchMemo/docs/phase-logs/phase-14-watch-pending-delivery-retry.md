# Phase 14 Log: Watch Pending Delivery Retry

Date: 2026-06-03

## Goal

Recover Watch recordings that are stuck waiting for iPhone import
acknowledgement.

## Why This Phase

Phase 13 made `transferredToPhone` stricter: it now means iPhone import was
acknowledged. That is a better success boundary, but it means a recording can
remain in `sendingToPhone` if the acknowledgement is delayed or missed.

The previous retry pass only retried `recorded` and `failed`, so those
unacknowledged recordings could stay stuck.

## What Changed

- Added `WatchDeliveryCore` with tests for Watch delivery retry policy.
- `DeliveryQueue.retryPending()` now retries recordings in:
  - `recorded`,
  - `sendingToPhone`,
  - `failed`.
- `transferredToPhone` remains the only non-retry state.

## Why Retrying Is Safe

The retry sends the original Watch audio file with the same recording ID. The
iPhone inbox import path uses that ID, so duplicate delivery replaces the
existing recording entry instead of creating a second independent inbox item.

## Out Of Scope

- Timer-based retry while the Watch app stays active.
- Retry counters and backoff.
- Watch local file deletion after confirmed import.
- Detailed iPhone import failure messages.
- Chunked long-recording transfer.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/WatchDeliveryCore
```

Result:

- 2 tests passed.
- Tests cover retryable unconfirmed states and the acknowledged terminal state.

Pending final validation in this phase:

- `WatchMemoMessageCore` tests.
- `PhoneInboxCore` tests.
- iOS Simulator build.
- Real iPhone destination build.
- True-device install and launch.

## True-Device Test

Record on Watch and confirm the normal flow still succeeds:

- iPhone receives the recording.
- Watch reaches final `Transferred to iPhone`.
- No duplicate visible iPhone inbox item is created for one recording.

A forced stuck-`sendingToPhone` recovery test can be added later once we expose
a debug action or manifest editor for that state.
