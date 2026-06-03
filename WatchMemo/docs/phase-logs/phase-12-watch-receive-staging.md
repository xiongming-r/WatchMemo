# Phase 12 Log: Watch Receive Staging Fix

Date: 2026-06-03

## Goal

Fix a real-device long-recording receive failure where the iPhone reported:

```text
Receive failed: The file "watchmemo-2026-06-03T02-30-13Z.m4a" doesn't exist.
```

## Root Cause

The Watch app completed recording and WatchConnectivity delivered a file
callback to the iPhone, but the iPhone receiver deferred importing
`WCSessionFile.fileURL` onto the main actor. That URL points to a
WatchConnectivity-managed temporary file, so it can disappear after the
delegate callback returns.

Short recordings may import before the temporary file is cleaned up, while
longer recordings are more likely to hit the race.

## What Changed

- In `PhoneConnectivityReceiver.session(_:didReceive:)`, copy the received
  `WCSessionFile.fileURL` immediately inside the delegate callback.
- Store that copy under the app temporary directory before handing work to the
  main actor.
- Import the recording from the staged copy, then remove the staged temporary
  copy after import.

## Out Of Scope

- Watch-side delivery acknowledgement from iPhone import.
- Chunked long-recording upload.
- Background transfer retry policy.
- Provider payload-size handling.

## Next Reliability Improvement

Add an explicit iPhone import acknowledgement. The Watch currently marks a file
as transferred when the WatchConnectivity transfer finishes, but the stronger
state should be "iPhone imported and persisted this recording."

## Validation

Pending true-device validation after install:

- Record another 2-minute clip on Apple Watch.
- Confirm the iPhone receives it without the missing-file error.
- Confirm the iPhone row shows a non-zero audio size.
- Run AI processing and record the displayed processing duration.
