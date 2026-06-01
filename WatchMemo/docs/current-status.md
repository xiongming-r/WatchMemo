# Current Status

Last updated: 2026-06-01 12:00 Asia/Shanghai

## Current Phase

Phase 0 is complete.

Latest local checkpoint:

- `docs/phase-logs/phase-7-mimo-audio-schema-fix.md`

Latest fully completed checkpoint:

- `docs/phase-logs/phase-6-openai-compatible-provider.md`

Next active phase:

- Real iPhone + Apple Watch validation for provider settings, API key storage,
  audio-understanding note generation, and WatchConnectivity.

## Product Direction

Build WatchMemo as a watchOS-first recording tool with an iPhone companion app.

The watch app should only do fast capture at first:

- Start recording.
- Stop recording.
- Save recording safely.
- Show trustworthy status.

The iPhone app and backend will later handle:

- Card list.
- Playback.
- Tags and notes.
- Transcription.
- Summary.
- Action items.
- Search.

## Next Concrete Action

Continue with provider and persistence work:

- The iPhone inbox now persists imported recordings.
- Debug builds can generate and import a local sample audio file without a real
  watch.
- The local transcript pipeline can create raw and cleaned drafts with a fake
  provider.
- Transcript drafts now persist locally and reload on app startup.
- Provider configuration now defines fake, OpenAI-compatible, and local command
  provider kinds.
- Provider settings and Keychain API key storage now exist in the iPhone app.
- The iPhone app can select fake or audio-understanding provider.
- Real network calls are enabled only when audio understanding is selected and
  an API key is saved.
- The first real iPhone command-line build and install succeeded after enabling
  Developer Mode and trusting the Personal Team profile.
- MiMo audio understanding now uses the documented data URI `input_audio`
  shape and defaults to `mimo-v2.5`.
- The iPhone status/error area now has a one-tap copy button for sharing
  provider errors during real-device testing.
- Phase 7 is not complete until the user validates on real hardware.

## Guardrails

- Do not build backend features before watch recording works.
- Do not build Xiaomi/Huawei versions before the watchOS MVP is proven.
- Do not add complex AI features before file recording and transfer are stable.
- Do not couple recording storage directly to one destination; always keep a
  local queue and metadata state.
- Keep each phase documented before moving to the next one.

## Files To Read First In A Future Session

1. `README.md`
2. `docs/current-status.md`
3. `docs/decision-log.md`
4. Latest file under `docs/phase-logs/`

## Latest Build Result

- 2026-05-29: `WatchMemoWatch` command-line build succeeded with Xcode 26.2.
- 2026-05-29: Installed watchOS 26.2 Simulator Runtime, launched the prototype
  on Apple Watch Series 11 (46mm), granted microphone permission, and validated
  a 3-second Debug self-test recording saved as `.m4a`.
- Limitation: manual button tapping was not fully validated through automation;
  real Apple Watch behavior still needs validation.
- 2026-05-29: Completed pre-Phase-2 research on open-source building blocks.
  No all-in-one open-source WatchMemo equivalent was found, but Apple
  WatchConnectivity, Communicator, SwiftWhisper, TUSKit, and Obsidian export
  options should shape later implementation choices.
- 2026-05-29: Added Phase 2 companion project with watch recording queue and
  WatchConnectivity relay stub. watchOS and iOS builds passed; simulator
  autotest created an `.m4a` and `recordings.json`.
- 2026-05-30: Added Phase 3 iPhone inbox core with Swift package tests, Debug
  simulated import, persisted iOS inbox, and playback. `swift test`, iOS build,
  and watchOS build passed.
- 2026-05-30: Added Phase 4 local transcript pipeline with fake provider,
  conservative filler cleanup, transcript draft UI action, and package tests.
- 2026-05-30: Added Phase 5 transcript draft persistence and provider
  configuration boundary. Drafts now survive app restart in the iPhone app.
- 2026-05-30: Added Phase 6 OpenAI-compatible remote transcription adapter.
  Tests validate multipart request shape, bearer authorization, JSON response
  parsing, and non-2xx failure handling. The app still defaults to fake provider.
- 2026-06-01: Added Phase 7 provider settings UI, Keychain API key storage, and
  runtime provider selection. Local tests and simulator builds passed. Device
  signing and true-device validation are still pending.
- 2026-06-01: Adjusted the real provider strategy to direct audio
  understanding: `POST /chat/completions` with base64 audio replaces
  transcription-only `POST /audio/transcriptions`.
- 2026-06-01: Fixed MiMo audio request compatibility after the real iPhone API
  test returned `No endpoints found that support image input`. The app now
  sends `data:audio/m4a;base64,...`, removes the separate `format` field,
  parses `reasoning_content` fallback, and defaults to `mimo-v2.5`.
