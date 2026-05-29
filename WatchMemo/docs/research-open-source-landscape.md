# Research: Open Source And Existing Building Blocks

Date: 2026-05-29

## Research Question

Before starting Phase 2, check whether there are existing open-source projects
or libraries that already solve parts of WatchMemo:

- watchOS audio recording.
- Apple Watch to iPhone file transfer.
- Direct upload or resumable upload.
- Speech transcription.
- AI cleanup / post-processing.
- Export to Obsidian or another knowledge base.

## Short Answer

No single open-source project appears to solve the full WatchMemo product:

```text
Apple Watch quick recording
  -> reliable local queue
  -> iPhone relay and/or direct upload
  -> AI transcription
  -> faithful cleanup
  -> knowledge-base export
```

However, there are useful pieces worth borrowing or evaluating.

## Apple Watch To iPhone Transfer

### Apple Watch Connectivity Sample

Source:

- https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity

Useful findings:

- Apple provides an official sample for transferring data between a watchOS app
  and companion iOS app.
- The sample explicitly says to use a physical iPhone and Apple Watch for
  testing.
- It demonstrates Watch Connectivity background tasks.
- This should be the main reference for Phase 2.

### WCSession.transferFile

Source:

- https://developer.apple.com/documentation/watchconnectivity/wcsession/1615667-transferfile

Useful findings:

- `transferFile(_:metadata:)` sends a local readable file to the counterpart.
- Transfers are asynchronous and system-managed.
- The system may throttle delivery for performance and power.
- Apple states Simulator does not support `transferFile`; paired devices are
  needed for real validation.

Implication:

Phase 2 can build in simulator enough to compile and test UI, but real file
transfer must be validated with hardware.

### Communicator

Source:

- https://github.com/KaneCheshire/Communicator

License:

- MIT.

Useful findings:

- Wraps WatchConnectivity in a higher-level API.
- Has message types for immediate messages, guaranteed messages, context, and
  larger `Blob` transfers.
- It says `Blob`s are intended for larger data and can continue transferring
  even if the app is terminated.

Evaluation:

- Good candidate for study or adoption in Phase 2.
- Since the core of our product depends on reliability and clear transfer
  state, using or learning from this may save time.
- We should still understand the underlying WatchConnectivity behavior.

### WatchLink

Source:

- https://github.com/tareksabry1337/WatchLink

License:

- MIT.

Useful findings:

- Swift package for Apple Watch to phone messaging.
- Uses BLE discovery, HTTP + SSE, and WatchConnectivity in parallel.
- Messages are acked, retried, and deduplicated.
- The author says it fixes real-time message reliability, but does not replace
  `transferUserInfo` or `updateApplicationContext`.

Evaluation:

- Interesting for later real-time control/status messaging.
- Probably too new and too message-oriented for MVP audio file transfer.
- Worth revisiting if WatchConnectivity alone proves unreliable.

## Direct Watch Upload

### Apple watchOS Background URLSession

Sources:

- https://developer.apple.com/documentation/watchos-apps/making-background-requests
- https://developer.apple.com/documentation/watchkit/wkurlsessionrefreshbackgroundtask

Useful findings:

- watchOS can use background URL sessions.
- Background sessions persist even if the app closes.
- Background responses may be deferred based on system resources, network
  connectivity, and other conditions.
- Apple recommends smaller transfers for background requests.
- Apple notes watchOS apps have short runtime, so normal asynchronous transfers
  may not finish before suspension.

Evaluation:

- Direct Watch-to-cloud upload is feasible but should not be the only MVP path.
- Use it later as a fast path after we have a reliable queue and iPhone relay.

### tus / TUSKit

Sources:

- https://tus.io/
- https://github.com/tus/TUSKit

License:

- MIT.

Useful findings:

- tus is an open protocol for resumable file uploads over HTTP.
- TUSKit is an iOS Swift client that supports uploading raw data or file paths.
- The docs warn that background uploads are scheduled by the OS, can take time,
  and chunking is discouraged when relying on background uploads.

Evaluation:

- Useful later if we build our own upload backend and need resumability.
- Too much infrastructure for Phase 2.
- For MVP, a simple background `URLSession.uploadTask(with:fromFile:)` or iPhone
  relay is enough.

## Transcription And AI Processing

### WhisperBoard

Source:

- https://github.com/Saik0s/Whisperboard

License:

- GPL-3.0.

Useful findings:

- Open-source iOS app for recording, importing audio files, exporting audio,
  and transcribing with OpenAI Whisper / whisper.cpp.
- Built with SwiftUI, Tuist, and The Composable Architecture.
- Lets users browse and download Whisper models.

Evaluation:

- Strong reference for iOS audio/transcription UX and local Whisper integration.
- GPL-3.0 means we should not copy code into this project unless we are ready to
  adopt GPL compatibility obligations.
- Good as architecture inspiration, not as direct dependency.

### SwiftWhisper

Source:

- https://github.com/exPHAT/SwiftWhisper

License:

- MIT.

Useful findings:

- Swift package wrapping whisper.cpp.
- Accepts 16 kHz PCM frames and returns transcription segments.
- Provides delegate callbacks for progress, segments, completion, and errors.

Evaluation:

- Good candidate for iPhone-side local transcription experiments.
- Watch-side local Whisper is likely too heavy for our early product.
- Need separate research on model size, Chinese accuracy, battery, and runtime
  on iPhone.

### JustSpeakToIt

Source:

- https://www.justspeaktoit.com/

Useful findings:

- Open-source Mac/iOS transcription product.
- Supports on-device Apple Speech and cloud providers.
- Includes AI post-processing that removes filler words, fixes punctuation, and
  polishes prose.
- BYO API keys model.

Evaluation:

- Useful product reference for our "faithful cleanup" pipeline.
- Not watchOS-focused, but validates the direction of raw transcript -> cleaned
  text.

## Obsidian And Knowledge Base Export

### Obsidian Local REST API

Source:

- https://github.com/coddingtonbear/obsidian-local-rest-api

Useful findings:

- Obsidian community plugin exposing vault notes through authenticated REST API.
- Supports reading, creating, updating, deleting, searching, and patching notes.
- Also exposes an MCP server.
- Can use local HTTPS, and plain localhost HTTP if enabled.

Evaluation:

- Good optional desktop integration later.
- Not suitable as the first mobile/watch ingestion path because it requires
  Obsidian running with the plugin enabled on a reachable machine.
- For MVP, export Markdown from iPhone/backend first.

### Obsidian URI

Source:

- https://help.obsidian.md/uri

Useful findings:

- Obsidian supports custom URI actions such as opening and creating notes.

Evaluation:

- Good for a simple user-triggered export action.
- Less suitable for reliable background delivery from Apple Watch.

## Competitive / Product Signals

### V2N - Voice To Notes

Source:

- https://apps.apple.com/us/app/v2n-voice-to-notes/id6758005273

Useful findings:

- Commercial app claims Apple Watch voice capture and sync to Notion,
  Obsidian, Roam Research, Trello, Todoist, TickTick, Apple Reminders, and more.
- Claims transcription via Apple's on-device AI on iOS 26+.

Evaluation:

- Confirms the product category exists.
- We should differentiate on reliability, faithful cleanup, local-first storage,
  and transparent export.

### My Transcriber

Source:

- https://mytranscriber.app/

Useful findings:

- Focuses on taking Apple Voice Memos from Apple Watch/iPhone/Mac and producing
  Markdown transcripts.
- Uses existing Apple Voice Memos as capture surface rather than building a
  watch recorder.

Evaluation:

- Important alternative path: integrate with system Voice Memos instead of
  replacing it.
- But system Voice Memos gives less control over tags, status, queue, and
  product UX.

## Recommendation For WatchMemo

### Phase 2

Do not adopt a large framework yet.

Build the standard Xcode iOS + watchOS companion project and implement
WatchConnectivity file transfer directly, using Apple sample code as the
reference.

Reason:

- We need to understand the exact lifecycle and background-task behavior.
- Apple says transferFile needs real paired-device testing.
- Audio file transfer is central enough that we should own the queue state and
  metadata model.

### Phase 3

Evaluate `Communicator` after the first direct implementation works.

Adopt it only if it clearly simplifies:

- Transfer state observation.
- Retry and reachability state.
- Large-file transfer handling.
- Background delivery handling.

### Phase 4

For transcription:

- Start with cloud transcription or iPhone-side processing.
- Evaluate SwiftWhisper for local transcription on iPhone.
- Use WhisperBoard only as a GPL-licensed reference, not copied code.

### Phase 5

For upload:

- Use native `URLSession` first.
- Consider TUSKit/tus only if we own the backend and need resumable large-file
  uploads.

### Knowledge Base Integration

First-class export format should be Markdown.

Initial integrations:

1. Share/export Markdown from iPhone.
2. Save Markdown to a user-selected folder if possible.
3. Obsidian URI for user-triggered note creation.
4. Obsidian Local REST API only as an advanced desktop/local-network
   integration.

## Updated Architecture Bias

The next engineering step remains Phase 2, but with one refinement:

Build the transfer layer as a replaceable `DeliveryQueue`, not as a hard-coded
"send to iPhone" feature.

```text
Recording
  -> LocalRecordingStore
  -> DeliveryQueue
      -> iPhoneRelayTransport
      -> DirectCloudUploadTransport later
      -> KnowledgeExportTransport later
```

