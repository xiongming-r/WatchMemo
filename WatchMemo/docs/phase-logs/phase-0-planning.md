# Phase 0: Planning and Project Memory

Date started: 2026-05-29
Date completed: 2026-05-29

## Goal

Create the initial product and technical direction for a smart-watch-first
recording product, and establish durable project memory before coding begins.

## Current Product Direction

WatchMemo starts as a watchOS + iPhone app.

The Apple Watch app is a one-tap capture tool for meetings, conversations, and
ideas. The iPhone app is the place to review recordings as cards, play audio,
edit titles/tags/notes, and trigger AI processing.

## MVP Boundary

Included:

- Watch recording.
- Watch-to-iPhone transfer.
- iPhone recording cards.
- Playback.
- Basic tags.
- Manual transcription and summary later.

Excluded for now:

- Team features.
- Enterprise workflows.
- Third-party integrations.
- Xiaomi/Huawei support.
- Real-time watch transcription.

## Key Unknowns

- How stable long recordings are on watchOS.
- How recording behaves when the watch screen sleeps.
- Whether background recording is acceptable for the intended use case.
- Transfer reliability for larger audio files.
- Best audio format for size, quality, and transcription.

## Completion Criteria

Phase 0 is complete when:

- Project directory exists. Done.
- Product plan exists. Done.
- Technical plan exists. Done.
- Decision log exists. Done.
- Next phase checklist is clear. Done.

## Work Log

- 2026-05-29: Created project memory structure under `WatchMemo/`.
- 2026-05-29: Added product plan, technical plan, decision log, phase template,
  current status, and Phase 1 checklist.
- 2026-05-29: Initialized Git repository and added Xcode-oriented `.gitignore`.

## Next Phase

Phase 1: watchOS recording prototype.

The next phase should create an Xcode iOS + watchOS project and implement the
smallest watch app that can request microphone permission, start recording,
stop recording, and save a playable local audio file.

Before beginning implementation, confirm the local machine has Xcode installed
and decide whether to create the Xcode project manually through Xcode or with a
project generator.
