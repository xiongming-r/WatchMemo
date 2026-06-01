# Phase 7 Fix: MiMo Audio Understanding Schema

Date: 2026-06-01

## Trigger

During real iPhone validation, the first audio-understanding request failed:

```text
Draft failed: Provider request failed (404): No endpoints found that support image input
```

MiMo's audio understanding documentation shows a provider-specific
OpenAI-compatible shape:

- `POST /chat/completions`
- model examples: `mimo-v2.5` and `mimo-v2-omni`
- audio content as `input_audio.data = data:audio/<type>;base64,<audio>`
- no separate `format` field
- useful text may be returned in `message.reasoning_content`

## What Changed

- Default model changed from `mimo-v2.5-pro` to `mimo-v2.5`.
- Audio payload changed from raw base64 plus `format` to a data URI:
  `data:audio/m4a;base64,...`.
- Removed the separate `input_audio.format` field.
- Response parsing now falls back from `message.content` to
  `message.reasoning_content`.
- JSON encoding now avoids escaping `/`, making captured request bodies easier
  to compare with provider docs.
- The iPhone status/error area now has a copy button for sharing provider
  errors during real-device testing.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

## Remaining Validation

- Rebuild and reinstall the iPhone app on the real device.
- In provider settings, set the endpoint to the MiMo OpenAI-compatible base URL
  and the model to `mimo-v2.5`.
- Run Debug import, tap the sparkle button, and confirm the returned draft text
  appears in the inbox row.
- If another provider error appears, use the new copy button and paste the exact
  status text back into the development thread.

## Follow-Up: Stale Inbox File URLs

The next real-device validation failed before reaching the provider:

```text
Draft failed: The file "84C028CD-2765-47D0-B8E2-AC35B37A9190.m4a" couldn't be opened because there is no such file.
```

Root cause: persisted `InboxRecording.fileURL` values were absolute sandbox
paths. Development installs can change the app container path while preserving
Documents content, so a manifest record can point at an old container. The
durable identity is `storedFileName`, not the absolute URL.

Fix: `PhoneInboxStore.loadRecordings()` now rebuilds each `fileURL` from the
current inbox `Audio/` directory plus `storedFileName`. A regression test covers
loading a manifest copied from an old container root into a new one.
