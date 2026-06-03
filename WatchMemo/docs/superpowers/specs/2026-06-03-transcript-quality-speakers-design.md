# Phase 16 Transcript Quality And Speaker Metrics Design

## Goal

Phase 16 makes long-recording validation more meaningful by turning messy speech into clearer record text and by showing lightweight text quality diagnostics on the iPhone.

## Scope

- Strengthen the OpenAI-compatible audio-understanding prompt so supported models remove fillers, repeated words, stutters, and meaningless pauses while preserving the speaker's original meaning.
- Ask the model to use `说话人 A/B/C` labels only when multiple speakers are clearly distinguishable from the audio.
- Add local metrics to each `TranscriptDraft`: raw character count, cleaned character count, compression ratio, removed filler count, segment count, segmented-processing flag, detected speaker labels, estimated speaker count, and whether speaker labels are present.
- Surface compact metrics in the iPhone inbox row so long tests can be evaluated without opening logs.

## Non-Goals

- Do not implement biometric speaker recognition or real identity matching.
- Do not force speaker labels for single-person notes or uncertain audio.
- Do not add a second transcription provider path in this phase.
- Do not change Obsidian export behavior beyond carrying the existing structured note text.

## Architecture

`OpenAICompatibleTranscriptProvider` remains responsible for provider-facing prompt and audio request shape. `TranscriptPipeline` remains responsible for converting provider output into a persisted `TranscriptDraft`. A new `TranscriptQualityMetrics` value is computed locally from raw text, cleaned text, removed fillers, and segment metadata, then stored with the draft.

The iPhone UI reads metrics from `TranscriptDraft` and displays them beside existing recording diagnostics. Legacy draft JSON remains readable by making metrics optional during decode.

## Data Flow

1. Watch recording arrives on iPhone.
2. iPhone chooses single-pass or segmented transcription.
3. Provider returns organized text.
4. Pipeline cleans or passes through provider text according to the selected provider.
5. Pipeline computes quality metrics.
6. Draft store persists text and metrics.
7. iPhone row displays audio size, AI time, text compression, segment count, and speaker estimate.

## Testing

- Unit tests verify metrics for single-pass drafts.
- Unit tests verify speaker label detection from `说话人 A/B/C` style output.
- Unit tests verify segmented drafts carry segment count and segmented-processing metadata.
- Unit tests verify legacy draft JSON without metrics still decodes.
- Unit tests verify the default provider instruction includes filler cleanup, speaker labeling, and no-fabrication requirements.

