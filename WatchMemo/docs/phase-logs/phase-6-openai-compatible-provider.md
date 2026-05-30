# Phase 6 Log: OpenAI-Compatible Provider Adapter

Date: 2026-05-30

## Goal

Add an OpenAI-compatible remote transcription adapter behind the existing
`TranscriptProvider` protocol, without requiring a real API key or network call
during local tests.

## What Changed

- Added `OpenAICompatibleTranscriptProvider`.
- Added `TranscriptHTTPClient` and `URLSessionTranscriptHTTPClient`.
- Added multipart request construction for `POST /audio/transcriptions`.
- Added bearer token authorization support.
- Added response parsing for JSON responses with a `text` field.
- Added provider errors for invalid configuration, invalid response, non-2xx
  responses, and missing transcript text.
- Added `ProviderConfiguration.openAICompatible(endpointURL:model:)`.
- Added tests for request shape, multipart body fields, response parsing, and
  failure handling.
- Added the new provider source file to the iPhone app target.

## Important Decisions

- The iPhone app still defaults to `FakeTranscriptProvider`.
- API key entry, secure storage, provider selection UI, and real network
  execution are intentionally not enabled yet.
- Tests use an injectable HTTP client, so they validate behavior without making
  external calls.
- The default OpenAI-compatible model is `gpt-4o-transcribe`, matching the
  current OpenAI speech-to-text direction; compatible providers can override the
  model via `ProviderConfiguration`.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Remaining Risks

- No real API key storage exists yet.
- No settings UI exists for choosing provider, endpoint, or model.
- The adapter has not been manually exercised against a real OpenAI-compatible
  endpoint.
- The adapter currently covers transcription only; model-based cleanup remains a
  future step.

## Next Candidate Phase

Phase 7 can make the remote provider usable in the app:

- Add secure API key storage using Keychain.
- Add a minimal provider settings screen.
- Add provider selection to `PhoneInboxViewModel`.
- Add visible error states for authentication, network, and API failures.
