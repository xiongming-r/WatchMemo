# Phase 18: Stitch UI Reference

Date: 2026-06-03

## Goal

Capture the Google Stitch export as a UI reference without coupling the project
to the generated HTML. The SwiftUI implementation should preserve the current
real-device MVP loop while moving the visual language closer to the Stitch
design.

## Source Asset

The local Stitch export lives at:

- `stitch_watchmemo_ai_voice_link/`

The folder contains six reference screens:

- Apple Watch ready-to-record screen
- Apple Watch active recording screen
- Apple Watch recent memo / transfer queue screen
- iPhone inbox screen
- iPhone AI result detail screen
- iPhone settings screen

The export also includes `watchmemo/DESIGN.md`, which defines a dark,
utility-minimal design system with functional status colors.

## Adopt Now

- Dark-first iPhone shell with card-based memo inbox.
- `All / Pending / Done / Failed` segmented filtering.
- Recording cards with title, timestamp, duration, size, source, status dot,
  and status action.
- Clear failed-state card with retry affordance.
- Processing card state that makes AI progress visible.
- Static bottom navigation placeholders for Inbox, Archive, and Settings.
- Settings/account/static future controls may show "coming soon" status instead
  of wiring new product behavior.

## Defer

- True waveform rendering.
- Archive behavior.
- Account/profile behavior.
- Watch pause/bookmark recording controls.
- A dedicated iPhone detail route if the first pass can expose AI content
  through expanded cards.

## Guardrails

- Do not break Watch recording, WatchConnectivity transfer, iPhone receipt, AI
  processing, Markdown copy, or Obsidian export.
- Missing features may appear as static UI only when they are visually useful,
  but taps must either do nothing harmless or show a clear "coming soon" status.
- Keep the generated Stitch HTML out of source control; commit only distilled
  design references and SwiftUI implementation.
