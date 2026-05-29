# Product Plan

## Working Name

WatchMemo

## One-Line Description

A smart-watch-first capture tool for quickly recording meetings,
conversations, and ideas, then turning them into searchable cards with
transcripts, summaries, and action items.

## Inspiration

Bluedot shows the broader opportunity: record conversations and meetings,
then generate useful meeting intelligence such as transcripts, summaries,
action items, and searchable records. WatchMemo borrows the idea of effortless
capture, but starts from the smart watch as the primary entry point.

## Product North Star

Make recording a meeting, conversation, or idea as fast as checking the time.

## Target Users

Initial target users:

- Founders and solo operators who frequently have informal conversations.
- Sales, consulting, and customer-facing workers who need quick follow-up notes.
- Product managers, designers, and researchers who capture meetings and ideas.
- Knowledge workers who want a low-friction personal memory tool.

The first MVP is optimized for an individual user, not a large enterprise team.

## Core Use Cases

1. Start recording a meeting from the watch in one tap.
2. Capture a short idea while walking or away from the phone.
3. Add a quick tag such as meeting, idea, customer, or todo.
4. Review recordings later on the iPhone as cards.
5. Convert a recording into transcript, summary, and action items.
6. Search across previous records.

## MVP Scope

The MVP should include:

- watchOS app with start, stop, pause/resume if feasible, and basic status.
- Local audio file storage on Apple Watch.
- Transfer recording files from Apple Watch to iPhone.
- iPhone app with a card list of recordings.
- Playback on iPhone.
- Basic tags and editable title.
- Manual transcription trigger.
- Generated transcript, summary, and action items.

## Explicit Non-Goals for MVP

These are intentionally out of scope for the first usable version:

- Enterprise admin console.
- Team workspace and permission model.
- CRM, ATS, or calendar integrations.
- Real-time transcription on the watch.
- Speaker diarization as a required feature.
- Android, Xiaomi, or Huawei wearable support.
- Perfect long-duration background recording before early prototyping proves it.

## User Experience Principles

- The watch app must be extremely simple.
- The iPhone app can carry complexity, but should still center on cards.
- Recording status must be obvious and trustworthy.
- Failure states must be recoverable: unsynced recordings should not disappear.
- Privacy and consent reminders must be clear.

## First Card Model

Each recording card should eventually contain:

- Title.
- Date and time.
- Duration.
- Source device.
- Tags.
- Audio file.
- Transcript.
- Summary.
- Action items.
- Freeform notes.
- Sync and processing state.

