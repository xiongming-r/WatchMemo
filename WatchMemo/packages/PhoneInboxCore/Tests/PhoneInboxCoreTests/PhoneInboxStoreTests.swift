import Foundation
import Testing
@testable import PhoneInboxCore

@Suite("Phone inbox store")
struct PhoneInboxStoreTests {
    @Test("default inbox directory avoids the iOS reserved Inbox folder")
    func defaultInboxDirectoryAvoidsReservedInboxName() {
        #expect(PhoneInboxStore.defaultRootDirectoryName == "WatchMemoInbox")
    }

    @Test("importing a recording copies audio and persists metadata")
    func importRecordingPersistsMetadata() throws {
        let root = try makeTemporaryDirectory()
        let source = root.appendingPathComponent("source.m4a")
        try Data("sample audio".utf8).write(to: source)

        let store = PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox"))
        let createdAt = Date(timeIntervalSince1970: 1_778_888_000)
        let imported = try store.importRecording(
            fileURL: source,
            metadata: InboxImportMetadata(
                id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
                originalFileName: "voice idea.m4a",
                createdAt: createdAt,
                durationSeconds: 12.5,
                source: .simulatedImport
            )
        )

        #expect(imported.originalFileName == "voice idea.m4a")
        #expect(imported.durationSeconds == 12.5)
        #expect(imported.source == .simulatedImport)
        #expect(imported.status == .readyForTranscription)
        #expect(imported.audioByteCount == 12)
        #expect(FileManager.default.fileExists(atPath: imported.fileURL.path))

        let reloadedStore = PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox"))
        let reloaded = try reloadedStore.loadRecordings()

        #expect(reloaded == [imported])
    }

    @Test("importing the same recording twice replaces the stored item")
    func repeatedImportReplacesExistingRecording() throws {
        let root = try makeTemporaryDirectory()
        let source = root.appendingPathComponent("source.m4a")
        try Data("first".utf8).write(to: source)

        let id = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let store = PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox"))

        _ = try store.importRecording(
            fileURL: source,
            metadata: InboxImportMetadata(
                id: id,
                originalFileName: "first.m4a",
                createdAt: Date(timeIntervalSince1970: 10),
                durationSeconds: 1,
                source: .watchConnectivity
            )
        )

        try Data("second".utf8).write(to: source)
        let imported = try store.importRecording(
            fileURL: source,
            metadata: InboxImportMetadata(
                id: id,
                originalFileName: "second.m4a",
                createdAt: Date(timeIntervalSince1970: 20),
                durationSeconds: 2,
                source: .simulatedImport
            )
        )

        let all = try store.loadRecordings()

        #expect(all.count == 1)
        #expect(all.first == imported)
        #expect(all.first?.originalFileName == "second.m4a")
        #expect(try Data(contentsOf: imported.fileURL) == Data("second".utf8))
    }

    @Test("loading recordings rebuilds file URLs for the current inbox root")
    func loadRecordingsRebuildsFileURLsForCurrentRoot() throws {
        let root = try makeTemporaryDirectory()
        let source = root.appendingPathComponent("source.m4a")
        try Data("sample audio".utf8).write(to: source)

        let oldRoot = root.appendingPathComponent("OldContainer")
        let newRoot = root.appendingPathComponent("NewContainer")
        let oldStore = PhoneInboxStore(rootDirectory: oldRoot)
        let imported = try oldStore.importRecording(
            fileURL: source,
            metadata: InboxImportMetadata(
                id: UUID(uuidString: "84C028CD-2765-47D0-B8E2-AC35B37A9190")!,
                originalFileName: "sample.m4a",
                createdAt: Date(timeIntervalSince1970: 1_778_920_000),
                durationSeconds: 0.8,
                source: .simulatedImport
            )
        )

        try FileManager.default.createDirectory(at: newRoot, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: oldRoot.appendingPathComponent("recordings.json"),
            to: newRoot.appendingPathComponent("recordings.json")
        )
        try FileManager.default.copyItem(
            at: oldRoot.appendingPathComponent("Audio", isDirectory: true),
            to: newRoot.appendingPathComponent("Audio", isDirectory: true)
        )

        let reloaded = try PhoneInboxStore(rootDirectory: newRoot).loadRecordings()

        #expect(reloaded.count == 1)
        #expect(reloaded.first?.storedFileName == imported.storedFileName)
        #expect(reloaded.first?.fileURL == newRoot.appendingPathComponent("Audio").appendingPathComponent(imported.storedFileName))
        #expect(FileManager.default.fileExists(atPath: reloaded.first?.fileURL.path ?? ""))
    }

    @Test("transcription state transitions persist without changing the audio file")
    func transcriptionStateTransitionsPersist() throws {
        let root = try makeTemporaryDirectory()
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio bytes".utf8).write(to: source)

        let id = UUID(uuidString: "12345678-1111-2222-3333-444444444444")!
        let store = PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox"))
        let imported = try store.importRecording(
            fileURL: source,
            metadata: InboxImportMetadata(
                id: id,
                originalFileName: "voice.m4a",
                createdAt: Date(timeIntervalSince1970: 100),
                durationSeconds: 9,
                source: .watchConnectivity
            )
        )

        try store.updateTranscriptionState(
            recordingID: id,
            status: .transcribing,
            errorMessage: nil,
            attemptedAt: Date(timeIntervalSince1970: 200),
            incrementsAttemptCount: true,
            durationSeconds: nil
        )
        try store.updateTranscriptionState(
            recordingID: id,
            status: .transcriptionFailed,
            errorMessage: "network offline",
            attemptedAt: Date(timeIntervalSince1970: 220),
            incrementsAttemptCount: false,
            durationSeconds: 18.25
        )

        let reloaded = try PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox")).loadRecordings()

        #expect(reloaded.first?.id == id)
        #expect(reloaded.first?.status == .transcriptionFailed)
        #expect(reloaded.first?.transcriptionErrorMessage == "network offline")
        #expect(reloaded.first?.transcriptionAttemptCount == 1)
        #expect(reloaded.first?.lastTranscriptionAttemptAt == Date(timeIntervalSince1970: 220))
        #expect(reloaded.first?.lastTranscriptionDurationSeconds == 18.25)
        #expect(reloaded.first?.storedFileName == imported.storedFileName)
        #expect(try Data(contentsOf: reloaded.first!.fileURL) == Data("audio bytes".utf8))
    }

    @Test("legacy recording manifests decode with transcription defaults")
    func legacyRecordingManifestDecodesWithDefaults() throws {
        let root = try makeTemporaryDirectory()
        let inbox = root.appendingPathComponent("Inbox")
        let audio = inbox.appendingPathComponent("Audio", isDirectory: true)
        try FileManager.default.createDirectory(at: audio, withIntermediateDirectories: true)
        try Data("legacy audio".utf8).write(to: audio.appendingPathComponent("legacy.m4a"))

        let json = """
        [
          {
            "createdAt" : 100,
            "durationSeconds" : 3.5,
            "fileURL" : "\(audio.appendingPathComponent("legacy.m4a").path)",
            "id" : "99999999-8888-7777-6666-555555555555",
            "importedAt" : 120,
            "originalFileName" : "legacy.m4a",
            "source" : "watchConnectivity",
            "status" : "readyForTranscription",
            "storedFileName" : "legacy.m4a"
          }
        ]
        """
        try json.data(using: .utf8)!.write(to: inbox.appendingPathComponent("recordings.json"))

        let recordings = try PhoneInboxStore(rootDirectory: inbox).loadRecordings()

        #expect(recordings.first?.status == .readyForTranscription)
        #expect(recordings.first?.transcriptionErrorMessage == nil)
        #expect(recordings.first?.transcriptionAttemptCount == 0)
        #expect(recordings.first?.lastTranscriptionAttemptAt == nil)
        #expect(recordings.first?.audioByteCount == nil)
        #expect(recordings.first?.lastTranscriptionDurationSeconds == nil)
    }

    @Test("interrupted transcriptions are marked failed and retryable")
    func interruptedTranscriptionsBecomeFailed() throws {
        let root = try makeTemporaryDirectory()
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio bytes".utf8).write(to: source)
        let store = PhoneInboxStore(rootDirectory: root.appendingPathComponent("Inbox"))
        let interruptedID = UUID(uuidString: "CCCCCCCC-1111-2222-3333-444444444444")!
        let completedID = UUID(uuidString: "DDDDDDDD-1111-2222-3333-444444444444")!

        _ = try store.importRecording(
            fileURL: source,
            metadata: InboxImportMetadata(
                id: interruptedID,
                originalFileName: "interrupted.m4a",
                createdAt: Date(timeIntervalSince1970: 10),
                durationSeconds: 5,
                source: .watchConnectivity
            )
        )
        _ = try store.importRecording(
            fileURL: source,
            metadata: InboxImportMetadata(
                id: completedID,
                originalFileName: "completed.m4a",
                createdAt: Date(timeIntervalSince1970: 20),
                durationSeconds: 6,
                source: .watchConnectivity
            )
        )
        try store.updateTranscriptionState(
            recordingID: interruptedID,
            status: .transcribing,
            errorMessage: nil,
            attemptedAt: Date(timeIntervalSince1970: 30),
            incrementsAttemptCount: true,
            durationSeconds: nil
        )
        try store.updateTranscriptionState(
            recordingID: completedID,
            status: .draftReady,
            errorMessage: nil,
            attemptedAt: Date(timeIntervalSince1970: 40),
            incrementsAttemptCount: true,
            durationSeconds: 4.5
        )

        let changedCount = try store.markInterruptedTranscriptionsFailed(
            message: "Interrupted before finishing. Tap retry.",
            at: Date(timeIntervalSince1970: 50)
        )
        let recordings = try store.loadRecordings()
        let interrupted = recordings.first { $0.id == interruptedID }
        let completed = recordings.first { $0.id == completedID }

        #expect(changedCount == 1)
        #expect(interrupted?.status == .transcriptionFailed)
        #expect(interrupted?.transcriptionErrorMessage == "Interrupted before finishing. Tap retry.")
        #expect(interrupted?.transcriptionAttemptCount == 1)
        #expect(interrupted?.lastTranscriptionAttemptAt == Date(timeIntervalSince1970: 50))
        #expect(completed?.status == .draftReady)
        #expect(completed?.transcriptionErrorMessage == nil)
        #expect(completed?.lastTranscriptionDurationSeconds == 4.5)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhoneInboxStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
