# Long Audio Segmentation Design

Date: 2026-06-03

## Goal

Support longer recordings by processing audio adaptively: short recordings stay
single-pass, while long or large recordings are split into model-friendly
segments.

## Model Assumptions

Current research indicates that modern audio-understanding models can often
accept much longer audio than a short meeting clip, but practical app limits
still come from request size, provider timeouts, retry cost, and quality drift.

For WatchMemo v0:

- Do not split recordings shorter than 10 minutes and smaller than 5 MB.
- Split recordings longer than 10 minutes or larger than 5 MB.
- Use 5-minute segments with 15-second overlap.

## Design

Add a pure Swift long-audio strategy:

```text
duration <= 10 minutes and bytes <= 5 MB -> single pass
duration > 10 minutes or bytes > 5 MB -> segmented pass
```

For segmented processing, the iPhone app creates temporary `.m4a` segments with
AVFoundation. Each segment is sent to the existing audio-understanding provider.
The pipeline then combines segment texts in order and formats one final
structured note.

The combined text includes segment boundaries internally during assembly, but
the final draft remains a single `TranscriptDraft` for the original recording.

## Why This Shape

- 60-second chunks are too small for meeting context and create too many API
  requests.
- 5-minute chunks preserve local context while reducing the chance that one
  provider request becomes too heavy.
- 15-second overlap protects against sentence cuts near boundaries.
- Reusing the existing provider avoids introducing a second text-only model
  contract before the audio path is stable.

## Components

- `LongAudioProcessingCore`: tested segment decision and segment planning.
- `TranscriptPipeline.makeDraftFromSegments`: transcribes multiple segment files
  and merges them into one draft.
- `AudioSegmentExporter`: iPhone-only AVFoundation helper that exports temporary
  `.m4a` segment files.
- `PhoneInboxViewModel`: chooses single-pass or segmented processing.

## Out Of Scope

- Text-only second-pass model merge.
- Per-segment persistent status UI.
- Background continuation if the app leaves foreground.
- Parallel segment requests.
- Chunked Watch-to-iPhone transfer.

## Validation

- Unit tests cover split decision thresholds and segment boundaries.
- Unit tests cover ordered segment transcript merging.
- App builds pass for simulator and real iPhone destination.
- True-device test starts with a 10-15 minute recording or a debug-generated
  large recording, then validates one final draft is produced.
