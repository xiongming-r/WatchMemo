# Stitch Inbox UI Design

Date: 2026-06-03

## Scope

Implement the first UI pass inspired by the Stitch export, focused on the iPhone
inbox. The result should look materially closer to the Stitch main inbox screen
while preserving the existing production behavior.

## iPhone Inbox

The current `List`-based inbox becomes a dark custom scroll view:

- Top app bar with `WatchMemo`, Provider settings, Obsidian settings, and a
  static account placeholder.
- Status strip with current app/provider status and one-tap copy.
- Segmented filter for all, pending, done, and failed recordings.
- Card stack for recordings.
- Static bottom navigation with Inbox, Archive, and Settings; Archive and
  Settings placeholder taps show "coming soon" or open existing settings where
  available.

Each recording card displays:

- Best available title: structured note title when present, otherwise original
  file name.
- Creation date or relative freshness.
- Duration, size, and source chips.
- Status dot and state text.
- AI processing affordance, retry/refresh affordance, playback, Markdown copy,
  and Obsidian export actions.
- Existing diagnostics such as enhanced audio, segment count, and speaker count.

## Behavior Mapping

- `Done`: recordings with `draftReady`.
- `Failed`: recordings with `transcriptionFailed`.
- `Pending`: recordings that are queued, interrupted, not yet drafted, or
  actively transcribing.
- `All`: every recording.

Static or future controls:

- Account button: shows `Account is not implemented yet`.
- Archive tab: shows `Archive is not implemented yet`.
- Bottom Settings tab: opens Provider settings first, because provider
  configuration is the most frequent setup task today.

## Testing

Run Swift package regression tests for the existing behavior packages and build
the iOS simulator app. Visual validation is manual through the simulator or real
iPhone after install.
