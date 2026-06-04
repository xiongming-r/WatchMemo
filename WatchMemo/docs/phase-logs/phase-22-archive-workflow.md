# Phase 22: Archive Workflow

Date: 2026-06-04

## Goal

Turn Archive from a static placeholder into a real user workflow state:
processed memos can leave the active Inbox without losing their audio, AI
draft, Markdown copy, playback, or Obsidian export paths.

## Product Definition

Archive means:

- the memo no longer needs attention in Inbox,
- the audio file remains stored locally,
- AI draft data remains available,
- Markdown copy and Obsidian export still work,
- the memo can be restored to Inbox later.

Archive does not mean:

- delete,
- upload,
- Obsidian delivery,
- permanent completion,
- hidden from recovery.

## Implemented

- Added durable archive metadata to `InboxRecording`:
  - `isArchived`
  - `archivedAt`
- Legacy recording manifests decode as unarchived by default.
- Added `PhoneInboxStore.setArchiveState(...)`.
- Added `PhoneInboxViewModel.archive(recording:)` and
  `PhoneInboxViewModel.restore(recording:)`.
- Inbox now shows only unarchived recordings.
- Archive now shows only archived recordings.
- Bottom navigation now switches between real Inbox and Archive views.
- Detail pages show an archive state panel:
  - unarchived memos can be archived,
  - archived memos can be restored to Inbox.
- Archiving does not remove audio files, transcript drafts, copy actions, or
  Obsidian export.

## Decisions Made

- Decision: persist archive state in the recording manifest.
  Reason: the manifest is already the source of truth for recording lifecycle
  state and survives app relaunches.
- Decision: keep archive manual.
  Reason: exporting to Obsidian or copying Markdown should not silently remove a
  memo from Inbox before the user confirms it is handled.
- Decision: add the archive action on the detail page instead of every card.
  Reason: archiving is a state transition that should happen after review, not
  a high-frequency card-list action.

## Risks Found

- Risk: there is no dedicated iOS UI test target to tap through archive and
  restore.
  Mitigation: core persistence behavior is covered by `PhoneInboxCore` tests,
  and the iPhone app is build-validated.
- Risk: archived memo sorting currently follows the existing manifest order.
  Mitigation: `archivedAt` is now stored, so a later pass can sort Archive by
  archive time without changing persistence format.

## Validation

- Red test first: `PhoneInboxCore` initially failed because `InboxRecording`
  lacked `isArchived` / `archivedAt` and `PhoneInboxStore` lacked
  `setArchiveState(...)`.
- `PhoneInboxCore` tests now pass with 8 tests:

```sh
swift test --package-path WatchMemo/packages/PhoneInboxCore
```

- iOS Simulator build passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/WatchMemoPhase22ArchiveSimDerivedData build
```

- Concrete real-iPhone build passed:

```sh
xcodebuild -project WatchMemo/apps/companion/WatchMemo.xcodeproj -scheme WatchMemo -destination 'id=E55C80BD-27F4-51B2-A22E-CAB28F3EBC95' -allowProvisioningUpdates -derivedDataPath /private/tmp/WatchMemoPhase22ArchiveDeviceDerivedData build
```

- The updated app installed on the real iPhone:

```sh
xcrun devicectl device install app --device E55C80BD-27F4-51B2-A22E-CAB28F3EBC95 /private/tmp/WatchMemoPhase22ArchiveDeviceDerivedData/Build/Products/Debug-iphoneos/WatchMemo.app
```

- Launch from command line was denied because the iPhone was locked:

```text
Unable to launch com.watchmemo.app because the device was not, or could not be, unlocked.
```

## Next Phase Notes

- True-device validation should check:
  - archive a memo from its detail page,
  - confirm it disappears from Inbox,
  - confirm it appears in Archive,
  - confirm playback / copy / Obsidian export still work,
  - restore it and confirm it returns to Inbox.
- Later iterations can add archive-time sorting, swipe actions, and optional
  "suggest archive after Obsidian export" behavior.
