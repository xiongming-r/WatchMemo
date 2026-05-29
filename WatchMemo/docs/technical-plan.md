# Technical Plan

## Platform Choice

Start with watchOS and an iPhone companion app.

Rationale:

- The development path is comparatively mature.
- Xcode supports creating iOS plus watchOS companion apps together.
- Watch Connectivity can transfer data and files between Apple Watch and iPhone.
- AVFoundation can be used for audio recording.
- The iPhone can handle UI-heavy review workflows and cloud upload.

Xiaomi and Huawei wearable platforms remain future research items after the
watchOS MVP proves the core workflow.

## High-Level Architecture

```text
Apple Watch app
  - one-tap recording
  - local audio file storage
  - lightweight tags/status
        |
        | Watch Connectivity
        v
iPhone app
  - recording card list
  - playback
  - edit title/tags/notes
  - upload for AI processing
        |
        | HTTPS API
        v
Backend
  - file upload
  - transcription
  - summary
  - action item extraction
  - search/indexing later
```

## Initial Technology Stack

Recommended first stack:

- Swift and SwiftUI for iOS and watchOS apps.
- AVFoundation for local audio recording.
- WatchConnectivity for watch-to-iPhone transfer.
- Local file storage for raw audio in the prototype.
- SwiftData or Core Data later for persistent card metadata.
- Backend choice deferred until after local recording and transfer are proven.

## Phase 1 Technical Goal

Build the smallest possible watchOS prototype that can:

1. Ask for microphone permission.
2. Start recording.
3. Stop recording.
4. Save a playable audio file locally.
5. Show a clear recording state.

This phase should be validated on a real Apple Watch if possible, because
simulator behavior is not enough for audio, battery, and lifecycle confidence.

## Main Technical Risks

- watchOS background execution and long recording stability.
- Battery drain and heat during long recordings.
- Audio permission and lifecycle edge cases.
- File transfer timing and reliability between watch and iPhone.
- User trust if a recording silently fails.
- Privacy and legal requirements around recording conversations.

## Future Platform Notes

### Xiaomi / HyperOS / Vela

Potentially useful for a later JavaScript-like wearable app path. Research is
needed around microphone APIs, background behavior, app distribution, and phone
sync.

### Huawei / HarmonyOS / Wear Engine

Useful for phone-wearable communication and ecosystem integration. Research is
needed around audio capture support, app review, SDK access, and distribution.

## Engineering Rule

Do not introduce AI, backend, or cross-platform complexity before the watch
recording and iPhone transfer loop is proven.

