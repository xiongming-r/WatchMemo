# Audio Understanding Provider Design

Date: 2026-06-01

## Decision

WatchMemo's first real remote provider should default to an audio-understanding
model, not a speech-to-text-only model.

The current target model is `mimo-v2.5-pro`. The expected capability is direct
audio understanding: the provider receives the audio file and returns a polished
knowledge-base-ready note without changing the original meaning.

## Scope

This phase changes the existing OpenAI-compatible provider strategy from:

```text
audio -> /audio/transcriptions -> raw transcript -> local filler cleanup
```

to:

```text
audio -> /chat/completions with audio input -> cleaned note
```

The app will still keep the fake provider for local testing.

## Follow-up Strategy

A later phase should add a processing mode selector:

- Audio understanding: model directly understands audio and returns a cleaned
  note.
- Speech-to-text only: model returns a raw transcript.
- Speech-to-text plus cleanup: ASR model returns raw text, then an LLM cleans and
  structures it.

## API Shape

The provider will call an OpenAI-compatible chat endpoint:

```text
POST {endpoint}/chat/completions
```

The request contains:

- `model`
- a system instruction for faithful note cleanup
- a user message containing text instructions plus base64 audio input

The response reads `choices[0].message.content` as the cleaned note.

## Validation

Local validation must cover:

- request URL and authorization header
- JSON body containing model, cleanup instruction, audio format, and base64 audio
- response parsing from `choices[0].message.content`
- non-2xx error handling

True-device validation must still be completed by the user on iPhone and Apple
Watch hardware.
