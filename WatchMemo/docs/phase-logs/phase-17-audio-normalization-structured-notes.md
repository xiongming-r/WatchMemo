# Phase 17 Log: Audio Normalization And Structured Notes

Date: 2026-06-03

## Goal

Improve transcription usefulness for weak conversational recordings and make AI
drafts include real summaries instead of first-sentence previews.

## Evidence From The 1:30 Recording

The iPhone's second recording was:

- `4379CC55-CE89-4DEE-904E-1A29652BBDEC.m4a`
- Duration: `89.856s`
- Format: AAC-LC, 16 kHz, mono, about 24 kbps.
- Mean volume: `-45.1 dB`.
- Integrated loudness: `-45.1 LUFS`.
- Time below `-35 dB`: about `60.56s`, or `67.4%`.

A temporary dynamic normalization experiment raised the mean volume to about
`-26.5 dB` and reduced below-`-35 dB` time to about `0.77%`. This suggests
upload-time enhancement can reduce model pressure for weak watch recordings.

The same recording's existing AI output did contain dialogue text, but the
local formatter used the first sentence as summary. The missing-summary issue
was therefore a prompt/formatter issue, not only an audio issue.

## What Changed

- Provider instruction now asks for structured Markdown:
  - `# 标题`
  - `## 摘要`
  - `## 对话整理`
  - `## 关键结论`
  - `## 待办`
  - `## 标签`
- `TranscriptNoteFormatter` now parses those sections and keeps the old
  fallback for unstructured text.
- Speaker-label detection now recognizes Markdown labels such as
  `**说话人A（女）：**`.
- iPhone AI processing now attempts OpenAI-compatible upload-time audio
  enhancement:
  - original inbox recording remains unchanged,
  - temporary enhanced `.m4a` files are used only for the provider request,
  - enhancement failures fall back to the original file,
  - row diagnostics can show `Enhanced audio`.

## Important Boundary

This phase does not claim transcription accuracy is solved. It removes two
avoidable causes:

- weak audio is no longer sent to the model completely untreated,
- structured summaries are no longer guessed locally from the first sentence.

True quality validation still needs the user to rerun AI processing on the
same 1:30 recording and compare output.

## Validation

Passed:

```sh
swift test --package-path WatchMemo/packages/TranscriptPipelineCore
```

Result:

- 16 tests passed.
- Tests cover structured Markdown parsing, Markdown speaker labels, provider
  section prompt requirements, existing draft persistence, and provider
  request parsing.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/WatchMemoAudioNormalizeSimDerivedData \
  build
```

Passed after implementation:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
swift test --package-path WatchMemo/packages/NoteDeliveryCore
swift test --package-path WatchMemo/packages/LongAudioProcessingCore
swift test --package-path WatchMemo/packages/WatchDeliveryCore
swift test --package-path WatchMemo/packages/WatchMemoMessageCore
```

Result:

- `PhoneInboxCore`: 7 tests passed.
- `NoteDeliveryCore`: 4 tests passed.
- `LongAudioProcessingCore`: 4 tests passed.
- `WatchDeliveryCore`: 2 tests passed.
- `WatchMemoMessageCore`: 3 tests passed.

Passed:

```sh
xcodebuild \
  -project WatchMemo/apps/companion/WatchMemo.xcodeproj \
  -scheme WatchMemo \
  -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' \
  -allowProvisioningUpdates \
  -derivedDataPath /private/tmp/WatchMemoAudioNormalizeDeviceDerivedData \
  build
```

Installed and launched:

- iPhone app `com.watchmemo.app`.
- Watch app `com.watchmemo.app.watchkitapp`.

## Recommended True-Device Quality Test

1. On iPhone, tap refresh/AI on the existing `89.856s` recording.
2. Confirm the row shows `Enhanced audio` after draft creation.
3. Check whether the note has `摘要`, `对话整理`, `关键结论`, and `待办`.
4. Compare transcription accuracy against the previous draft for the same
   recording.
