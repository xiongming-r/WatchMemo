# Phase 5 Log: Transcript Persistence And Provider Boundary

Date: 2026-05-30

## Goal

Persist generated transcript drafts locally and define the provider configuration
boundary before adding any real transcription or AI API calls.

## What Changed

- Added `TranscriptDraftStore` to `TranscriptPipelineCore`.
- `TranscriptDraftStore` saves drafts to `transcript-drafts.json`.
- Saving a draft replaces an older draft for the same recording ID.
- Added `ProviderConfiguration` with provider kinds:
  - `fake`
  - `openAICompatible`
  - `localCommand`
- Added tests for draft persistence, replacement, and the fake provider
  boundary.
- Updated the iPhone app to load saved transcript drafts on startup.
- Updated the iPhone app to save a generated draft before showing it in the UI.

## Important Decisions

- This phase still does not call a real API.
- Draft persistence is local JSON for now, matching the current inbox storage
  pattern and keeping the system easy to inspect during prototype work.
- Provider configuration exists as a typed boundary, not as UI settings yet.
- The fake provider remains the app default until API key handling and real
  provider failure behavior are designed.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Passed:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemoWatch \
  -destination 'generic/platform=watchOS Simulator' \
  build
```

## Remaining Risks

- No real speech-to-text or AI cleanup provider is implemented yet.
- Drafts are persisted, but there is no user-facing draft management UI.
- API key storage, provider selection UI, retries, and network failure handling
  still need design before enabling a real provider.
- Real WatchConnectivity transfer remains deferred until paired hardware is
  available.

## Next Candidate Phase

Phase 6 can add a real provider adapter behind the existing protocol:

- Decide whether to start with OpenAI-compatible remote API or a local command
  provider.
- Add secure configuration handling.
- Add provider error states to the iPhone UI.
- Keep the fake provider available for simulator-only development.
