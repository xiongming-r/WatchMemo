# Current Status

Last updated: 2026-06-03 17:35 Asia/Shanghai

## Current Phase

Phase 0 is complete.

Latest completed checkpoint:

- `docs/phase-logs/phase-18-stitch-ui-reference.md`

Current active phase:

- Phase 19 Stitch-inspired iPhone inbox UI: convert the iPhone inbox from a
  system `List` into a dark card-based shell with filters, memo cards, status
  chips, static future controls, and clearer AI result previews.

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
- Debug builds can generate and import a local spoken Chinese sample audio file
  without a real watch.
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
- Inbox recordings now rebuild their audio file URLs from the current app
  container on load, avoiding stale absolute paths after development installs.
- The audio-understanding prompt now explicitly rejects hallucination when
  audio has no clear human speech.
- After upgrading the Mac and Xcode, local tooling is now `macOS 26.5` and
  `Xcode 26.5 (17F42)` with `watchOS 26.5` SDK.
- The iPhone app has been rebuilt, installed, and launched on the real iPhone.
- The Watch app has been rebuilt for the real Apple Watch destination, installed,
  and launched on the real Apple Watch.
- The first real Watch recording test saved audio locally but did not appear on
  the iPhone. Device inspection showed WatchConnectivity file transfers were
  still `transferring`, while the app had incorrectly marked them as
  `transferredToPhone`.
- The companion project now embeds `WatchMemoWatch.app` inside the iPhone app's
  `Watch/` directory, and Watch transfer state now waits for the
  WatchConnectivity completion callback before marking a recording transferred.
- Phase 7 is complete: the user confirmed real Apple Watch recording,
  iPhone receipt, and successful AI text output.
- Phase 8 is complete: new AI drafts now include a
  persisted structured note with title, body, summary, action items, tags, and
  Markdown; the iPhone row can copy Markdown.
- On 2026-06-02, the updated iPhone and Watch apps were rebuilt, installed, and
  launched on real devices. The user confirmed true-device validation passed:
  Apple Watch recording reached iPhone, AI processing produced structured note
  output, and Markdown copy was available.
- Phase 9 Obsidian Export v0 passed true-device validation on 2026-06-02: the
  iPhone app opened/created a note in iPhone Obsidian from a real watch
  recording's AI-generated text.
- Phase 10 true-device validation passed on 2026-06-02: iPhone-side AI
  processing state is persisted per recording, including status, error message,
  attempt count, failure retry, and interrupted-processing recovery.
- Phase 11 is in local development: each imported iPhone inbox recording now
  captures audio byte size, AI attempts can persist elapsed processing time,
  and the iPhone row displays compact diagnostic metrics for long-recording
  experiments.
- On 2026-06-03, a 2-minute real Watch recording exposed an iPhone receive
  failure: `Receive failed: The file ... doesn't exist.` The root cause is that
  `WCSessionFile.fileURL` is a WatchConnectivity temporary file. The iPhone app
  now stages the received file synchronously inside `didReceive file` before
  importing it on the main actor.
- Phase 13 is locally validated: after iPhone import succeeds, the iPhone
  enqueues a `watchmemo.importAcknowledged` user-info acknowledgement back to
  the Watch. The Watch now marks `transferredToPhone` only after this import
  acknowledgement is received.
- Phase 14 is in local validation: `DeliveryQueue.retryPending()` now treats
  `sendingToPhone` as retryable, so a recording waiting for a missed or delayed
  iPhone import acknowledgement can be resent on the next Watch queue prepare.
- Phase 15 is in local validation: recordings up to 10 minutes and 5 MB stay
  single-pass; longer or larger recordings are exported into temporary
  5-minute `.m4a` segments with 15-second overlap, transcribed in order, and
  merged into one final draft.
- Phase 16 is device-build validated: provider instructions now ask supported
  audio-understanding models to remove fillers, repeats, stutters, and
  meaningless pauses while preserving meaning. Drafts now persist local
  quality metrics, including text length compression, segment count, and
  detected `说话人 A/B/C` labels. The updated iPhone and Watch apps installed
  and launched on real devices; true long-recording quality validation remains
  pending.
- Phase 17 is device-build validated: the 89.856-second real iPhone recording
  was diagnosed as valid but weak (`-45.1 dB`, about `67.4%` below `-35 dB`).
  OpenAI-compatible processing now tries temporary upload-time audio
  enhancement before model calls, and structured Markdown sections are parsed
  into real title/summary/body/action/tag fields. The updated iPhone and Watch
  apps installed and launched on real devices; rerunning AI on the same 1:30
  recording is still pending.
- Phase 18 captured the Google Stitch export as a UI reference. The local export
  folder is intentionally ignored from git; the committed docs record the design
  direction and scope.
- Phase 19 is locally validated. The Stitch-inspired iPhone UI pass now uses
  a dark custom shell with status strip, filters, card stack, static future
  navigation entries, and expanded structured note previews. Core recording,
  playback, AI, Markdown copy, and Obsidian export actions remain wired to the
  existing implementation.

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
- 2026-06-01: Fixed a real-device file lookup failure after reinstall/update:
  persisted inbox records may contain stale absolute `fileURL` container paths,
  so `PhoneInboxStore.loadRecordings()` now rebuilds `fileURL` from
  `storedFileName` and the current inbox root.
- 2026-06-01: Replaced the Debug import's pure-tone sample with a spoken
  Chinese sample generated by `AVSpeechSynthesizer`, and strengthened the
  provider instruction to say not to invent content when no clear speech exists.
- 2026-06-01 18:15: After upgrading to `macOS 26.5` and `Xcode 26.5 (17F42)`,
  `xcodebuild -showsdks` reports `watchOS 26.5`. `devicectl` reports the
  Apple Watch developer mode enabled, DDI services available, and tunnel
  connected. The iPhone app installed/launched with bundle id
  `com.watchmemo.app`. The Watch app initially failed with a stale generic
  provisioning profile, then succeeded after rebuilding with the concrete Watch
  destination `00008310-001479040C8B601E`; it installed/launched with bundle id
  `com.watchmemo.app.watchkitapp`.
- 2026-06-01 18:30: Debugged the first failed Watch-to-iPhone transfer. The
  Watch had local recordings and pending WatchConnectivity `FileTransfers`, but
  the iPhone inbox did not receive them. Fixed the project to embed the Watch
  app inside the iPhone app and changed Watch delivery state so
  `transferFile(...)` queueing no longer masquerades as completed transfer.
- 2026-06-01 18:45: User confirmed the real-device MVP loop succeeds:
  Apple Watch records audio, iPhone receives and displays the recording, and
  the configured audio-understanding provider returns usable text.
- 2026-06-01 18:50: Added Phase 8 structured notes and Markdown copy. Local
  tests pass, iOS Simulator build passes, watchOS generic device build passes,
  and iOS generic device build passes after rerunning separately with its own
  DerivedData path.
- 2026-06-02 09:55: Phase 8 true-device validation passed. The command-line
  build for the real iPhone destination succeeded, `ValidateEmbeddedBinary`
  confirmed the embedded Watch app, both apps installed and launched on the
  user's real iPhone and Apple Watch, and the user confirmed the end-to-end
  structured note flow works on devices.
- 2026-06-02 12:05: Added Phase 9 Obsidian Export v0 locally. `NoteDeliveryCore`
  tests cover URL generation and long-content refusal. `TranscriptPipelineCore`
  and `PhoneInboxCore` tests still pass. iOS Simulator, watchOS generic, and
  iOS generic builds pass. True-device Obsidian validation is pending.
- 2026-06-02 14:20: Phase 9 true-device Obsidian validation passed. The updated
  iPhone and Watch apps installed and launched on real devices, and the user
  confirmed a real watch recording's AI-generated text exported into iPhone
  Obsidian.
- 2026-06-02 14:35: Phase 10 transcription reliability v0 is locally validated
  so far. `PhoneInboxCore` now persists draft processing state, error messages,
  attempt counts, and interrupted-processing recovery. `PhoneInboxCore` tests
  pass and the iOS Simulator app build passes.
- 2026-06-02 15:35: Phase 11 long-recording diagnostics v0 is locally
  validated. Imported inbox recordings now persist audio byte size, AI attempts
  persist elapsed processing time, and the iPhone row displays compact
  diagnostics. `PhoneInboxCore`, `TranscriptPipelineCore`, and
  `NoteDeliveryCore` tests pass; iOS Simulator and watchOS generic builds pass.
- 2026-06-03 10:45: Phase 12 diagnosed the real-device 2-minute receive error
  as a WatchConnectivity temporary-file lifetime race. The iPhone receiver now
  stages received files immediately in the delegate callback before importing
  them. Local package and app build validation is being rerun before true-device
  install.
- 2026-06-03 12:05: Phase 13 iPhone import acknowledgement is locally
  validated. `WatchMemoMessageCore` tests pass, `PhoneInboxCore` tests pass,
  iOS Simulator build passes, and the real iPhone destination build passes with
  embedded Watch app validation. True-device acknowledgement validation is
  pending after install.
- 2026-06-03 14:05: Phase 14 added a tested Watch delivery retry policy and
  updated `DeliveryQueue.retryPending()` so `recorded`, `sendingToPhone`, and
  `failed` recordings are retried, while `transferredToPhone` remains terminal.
  Final app build and install validation is pending.
- 2026-06-03 14:35: Phase 15 added `LongAudioProcessingCore`, ordered segment
  draft merging in `TranscriptPipelineCore`, and iPhone-side AVFoundation
  segment export for long or large recordings. Package tests, iOS Simulator
  build, real iPhone destination build, iPhone install/launch, and Watch
  install/launch pass. True-device long-recording AI validation is pending.
- 2026-06-03 15:35: Phase 16 added draft quality metrics and lightweight
  speaker-label detection. New tests cover single-pass metrics, segmented
  metrics, speaker labels, legacy draft decoding, and provider prompt
  constraints. Package tests pass, iOS Simulator build passes, real iPhone
  destination build passes, and the updated iPhone/Watch apps installed and
  launched on real devices. True long-recording quality validation is pending.
- 2026-06-03 16:25: Phase 17 diagnosed the user's 1:30 test recording and
  added structured-note parsing plus upload-time audio enhancement. The
  original recording is not modified; temporary enhanced `.m4a` files are used
  only for provider requests. Package tests pass, iOS Simulator build passes,
  real iPhone destination build passes, and the updated iPhone/Watch apps
  installed and launched on real devices. True quality validation on the same
  1:30 recording is pending.
- 2026-06-03 17:35: Phase 18/19 imported the Stitch design direction into docs
  and updated the iPhone inbox to a dark card-based SwiftUI shell. The first
  iOS Simulator build passed, all Swift package regressions passed, and the
  final iOS Simulator build passed. Optional true-device install remains
  pending.
