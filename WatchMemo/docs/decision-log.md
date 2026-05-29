# Decision Log

This file records decisions that should not be silently overwritten later.

## 2026-05-29: Start with watchOS

Decision:

Start the first implementation on watchOS with an iPhone companion app.

Why:

- The user is new to smart-watch development.
- Apple tooling is the most practical first learning path.
- Watch Connectivity gives an official path for watch-to-phone transfer.
- The iPhone can handle browsing, playback, upload, and richer UI.

Alternatives considered:

- Xiaomi / HyperOS / Vela first.
- Huawei / HarmonyOS first.
- Backend-first product prototype.

Why not alternatives now:

- Non-Apple wearable ecosystems add platform uncertainty before the core product
  behavior is proven.
- Backend-first development would delay the most important unknown: whether the
  watch can be a reliable capture surface.

## 2026-05-29: Treat the watch as capture surface only

Decision:

The watch app should focus on fast, reliable recording and minimal tagging.
Transcription, summaries, search, and workflow integrations belong on iPhone
and backend services.

Why:

- Smart watches have small screens, limited battery, and stricter lifecycle
  constraints.
- Product value comes from low-friction capture plus later intelligent
  organization.
- Keeping watch scope small makes the first prototype achievable.

## 2026-05-29: Maintain phase logs

Decision:

Every major phase gets a log under `docs/phase-logs/`.

Why:

- The project is long-running and may exceed conversation context.
- Phase logs prevent goal drift.
- Future sessions can resume from documented state rather than memory.

## 2026-05-29: Use a standard companion project for Phase 2

Decision:

Phase 2 should move from the hand-written standalone watchOS prototype project
to a standard Xcode-generated iOS + watchOS companion project.

Why:

- The hand-written target was useful for validating the recording code quickly.
- Installing to the watchOS Simulator exposed watch target metadata requirements
  such as `WKCompanionAppBundleIdentifier`.
- Changing the product type manually to `application.watchapp2` caused duplicate
  build outputs, which suggests more Xcode template-generated target settings
  are needed.
- Phase 2 needs Watch Connectivity and an iPhone companion anyway, so a standard
  companion project is the better foundation.

