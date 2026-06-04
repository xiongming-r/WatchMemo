import Foundation

public final class PhoneInboxStore {
    public static let defaultRootDirectoryName = "WatchMemoInbox"

    private let fileManager: FileManager
    private let rootDirectory: URL
    private let audioDirectory: URL
    private let manifestURL: URL

    public init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
        self.audioDirectory = rootDirectory.appendingPathComponent("Audio", isDirectory: true)
        self.manifestURL = rootDirectory.appendingPathComponent("recordings.json")
    }

    public convenience init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.init(
            rootDirectory: documents.appendingPathComponent(Self.defaultRootDirectoryName, isDirectory: true),
            fileManager: fileManager
        )
    }

    public func importRecording(fileURL: URL, metadata: InboxImportMetadata) throws -> InboxRecording {
        try ensureDirectoriesExist()

        let fileExtension = fileURL.pathExtension.isEmpty ? "m4a" : fileURL.pathExtension
        let storedFileName = "\(metadata.id.uuidString).\(fileExtension)"
        let destination = audioDirectory.appendingPathComponent(storedFileName)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.copyItem(at: fileURL, to: destination)
        let audioByteCount = try fileSize(at: destination)

        let recording = InboxRecording(
            id: metadata.id,
            originalFileName: metadata.originalFileName,
            storedFileName: storedFileName,
            createdAt: metadata.createdAt,
            importedAt: Date(),
            durationSeconds: metadata.durationSeconds,
            audioByteCount: audioByteCount,
            source: metadata.source,
            status: .readyForTranscription,
            fileURL: destination
        )

        var recordings = try loadRecordings()
        recordings.removeAll { $0.id == metadata.id }
        recordings.insert(recording, at: 0)
        try save(recordings)
        return recording
    }

    public func loadRecordings() throws -> [InboxRecording] {
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return []
        }

        let data = try Data(contentsOf: manifestURL)
        let recordings = try JSONDecoder().decode([InboxRecording].self, from: data)
        return recordings.map(recordingWithCurrentFileURL)
    }

    public func updateTranscriptionState(
        recordingID: InboxRecording.ID,
        status: InboxRecording.Status,
        errorMessage: String?,
        attemptedAt: Date,
        incrementsAttemptCount: Bool,
        durationSeconds: TimeInterval? = nil
    ) throws {
        var recordings = try loadRecordings()

        guard let index = recordings.firstIndex(where: { $0.id == recordingID }) else {
            return
        }

        recordings[index].status = status
        recordings[index].transcriptionErrorMessage = errorMessage
        recordings[index].lastTranscriptionAttemptAt = attemptedAt
        recordings[index].lastTranscriptionDurationSeconds = durationSeconds

        if incrementsAttemptCount {
            recordings[index].transcriptionAttemptCount += 1
        }

        try save(recordings)
    }

    public func markInterruptedTranscriptionsFailed(message: String, at date: Date) throws -> Int {
        var recordings = try loadRecordings()
        var changedCount = 0

        for index in recordings.indices where recordings[index].status == .transcribing {
            recordings[index].status = .transcriptionFailed
            recordings[index].transcriptionErrorMessage = message
            recordings[index].lastTranscriptionAttemptAt = date
            changedCount += 1
        }

        guard changedCount > 0 else {
            return 0
        }

        try save(recordings)
        return changedCount
    }

    public func setArchiveState(recordingID: InboxRecording.ID, isArchived: Bool, at date: Date) throws {
        var recordings = try loadRecordings()

        guard let index = recordings.firstIndex(where: { $0.id == recordingID }) else {
            return
        }

        recordings[index].isArchived = isArchived
        recordings[index].archivedAt = isArchived ? date : nil
        try save(recordings)
    }

    private func ensureDirectoriesExist() throws {
        try fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
    }

    private func recordingWithCurrentFileURL(_ recording: InboxRecording) -> InboxRecording {
        InboxRecording(
            id: recording.id,
            originalFileName: recording.originalFileName,
            storedFileName: recording.storedFileName,
            createdAt: recording.createdAt,
            importedAt: recording.importedAt,
            durationSeconds: recording.durationSeconds,
            audioByteCount: recording.audioByteCount,
            source: recording.source,
            status: recording.status,
            transcriptionErrorMessage: recording.transcriptionErrorMessage,
            transcriptionAttemptCount: recording.transcriptionAttemptCount,
            lastTranscriptionAttemptAt: recording.lastTranscriptionAttemptAt,
            lastTranscriptionDurationSeconds: recording.lastTranscriptionDurationSeconds,
            isArchived: recording.isArchived,
            archivedAt: recording.archivedAt,
            fileURL: audioDirectory.appendingPathComponent(recording.storedFileName)
        )
    }

    private func fileSize(at url: URL) throws -> Int64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }

    private func save(_ recordings: [InboxRecording]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(recordings)
        try data.write(to: manifestURL, options: .atomic)
    }
}
