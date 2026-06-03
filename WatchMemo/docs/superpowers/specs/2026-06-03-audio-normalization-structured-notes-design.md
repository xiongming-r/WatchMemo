# Phase 17 Audio Normalization And Structured Notes Design

## Goal

Improve real-device transcription usefulness for weak conversational recordings by preparing audio before upload and by producing notes with real summaries instead of first-sentence previews.

## Evidence

The 89.856-second iPhone recording `4379CC55-CE89-4DEE-904E-1A29652BBDEC.m4a` is a valid AAC-LC file, but its average level is low:

- AAC-LC, 16 kHz, mono, about 24 kbps.
- Mean volume: `-45.1 dB`.
- Integrated loudness: `-45.1 LUFS`.
- About `67.4%` of the recording is below `-35 dB`.

A temporary dynamic-normalization experiment raised mean volume to `-26.5 dB` and reduced below-`-35 dB` time to `0.77%`. That suggests upload-time audio enhancement can help without changing Watch capture behavior immediately.

The existing draft for the same recording shows a separate formatting issue: the model returned dialogue text, but `TranscriptNoteFormatter` used the first sentence as the summary. The missing-summary issue is therefore mostly a code/prompt structure problem.

## Scope

- Add upload-time audio preprocessing on iPhone for OpenAI-compatible provider calls.
- Keep the original received recording unchanged.
- Generate a temporary enhanced `.wav` file for AI requests when preprocessing succeeds.
- Preserve the original file as a fallback when preprocessing fails.
- Strengthen the provider instruction to request Markdown sections:
  - `# 标题`
  - `## 摘要`
  - `## 对话整理` or `## 正文`
  - `## 关键结论`
  - `## 待办`
  - `## 标签`
- Teach `TranscriptNoteFormatter` to parse those sections instead of using only first-sentence heuristics.
- Improve speaker-label detection to handle model output like `**说话人A（女）：**`.
- Surface audio enhancement status in iPhone diagnostics.

## Non-Goals

- Do not delete silence or trim the source recording in Phase 17.
- Do not implement provider-specific diarization.
- Do not run a second text-only model pass after transcription.
- Do not replace Watch recording architecture.
- Do not claim transcription accuracy is fixed without true-device retesting.

## Architecture

`PhoneInboxViewModel` gets a private AVFoundation-based `AudioUploadPreprocessor`. It reads the selected recording or segment, computes RMS/peak diagnostics, applies conservative per-window gain to weak audio, writes a temporary `.wav`, and passes that URL to `TranscriptPipeline`. Temporary enhanced files are removed after the draft attempt.

`OpenAICompatibleTranscriptProvider` keeps the same chat completion request shape, but its default instruction asks for structured Markdown sections and optional speaker labels. `TranscriptNoteFormatter` parses Markdown sections into `StructuredTranscriptNote`, while preserving its legacy fallback for unstructured provider output.

## Testing

- Unit tests verify structured Markdown parsing for title, summary, body, action items, and tags.
- Unit tests verify speaker-label detection handles Markdown bold labels and labels without spaces.
- Unit tests verify provider instructions include the required section headings.
- App builds verify the iPhone preprocessor compiles against AVFoundation.

