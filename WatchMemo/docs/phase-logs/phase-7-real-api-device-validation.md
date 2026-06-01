# Phase 7 Log: Real API Provider Settings, Pending Device Validation

Date: 2026-06-01

## Goal

Enable the iPhone app to use a real OpenAI-compatible transcription API while
keeping the API key out of source control. This phase is not considered complete
until real iPhone + Apple Watch validation passes.

## What Changed

- Added `ProviderRuntimeSettings` to `TranscriptPipelineCore`.
- Added tests for default fake provider settings and OpenAI-compatible runtime
  settings.
- Added `APIKeyStore`, backed by Keychain.
- Added `ProviderSettingsStore`, backed by `UserDefaults`, for non-secret
  provider settings.
- Added `ProviderSettingsView`, opened from the iPhone app toolbar.
- Updated `PhoneInboxViewModel` to build the transcript pipeline dynamically:
  - Fake provider remains the default.
  - OpenAI-compatible provider is used only when selected and an API key exists.
- Added localized provider error messages for better true-device debugging.

## Local Validation

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

Blocked for device signing:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS' \
  build
```

Result:

- `Signing for "WatchMemo" requires a development team.`
- This must be resolved in Xcode by selecting a Development Team for real-device
  builds.

## Real-Device Validation Checklist

Phase 7 is complete only after the user confirms:

1. Xcode signing is configured for the iPhone app target.
2. The app installs and launches on a real iPhone.
3. Provider settings opens from the gear button.
4. The user selects `OpenAI-compatible`.
5. Endpoint is `https://api.openai.com/v1` or another compatible endpoint.
6. Model is `gpt-4o-transcribe` or another compatible transcription model.
7. API key is saved, and the screen reports saved state.
8. A real or Debug-imported recording appears in the iPhone inbox.
9. Tapping the sparkle button sends a real transcription request.
10. A transcript draft appears and is persisted after app restart.

Apple Watch end-to-end validation should additionally confirm:

1. A recording is captured on the real Apple Watch.
2. The recording transfers to the iPhone app inbox.
3. The transferred recording can be transcribed through the real provider.

## Current Status

Ready for user device validation. Not yet marked complete.

## Remaining Risks

- Signing is not configured in the project for generic iOS device builds.
- The real API path has not been exercised with a live key yet.
- WatchConnectivity on paired hardware still needs validation.
- The settings UI is intentionally minimal and has no provider test button yet.

## Next Candidate Phase

After true-device validation:

- If validation passes, mark Phase 7 complete and start model-based cleanup or
  export planning.
- If validation fails, fix the specific device/API/WatchConnectivity failure
  before adding new features.
