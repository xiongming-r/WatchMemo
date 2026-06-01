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

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhoneInboxStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
