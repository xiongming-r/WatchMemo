# Current Status

Last updated: 2026-05-30 16:25 Asia/Shanghai

## Current Phase

Phase 0 is complete.

Latest completed checkpoint:

- `docs/phase-logs/phase-6-openai-compatible-provider.md`

Next active phase:

- Provider settings and secure API key handling, while real paired-device
  WatchConnectivity validation remains deferred.

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
- An OpenAI-compatible transcription provider adapter now exists and is covered
  by request/response tests.
- Next, add provider settings and secure API key storage before enabling real
  network calls from the app.
- Real WatchConnectivity file transfer still requires paired hardware later.

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
