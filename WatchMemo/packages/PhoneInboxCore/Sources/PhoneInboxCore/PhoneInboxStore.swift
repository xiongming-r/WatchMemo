import Foundation

public final class PhoneInboxStore {
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
        self.init(rootDirectory: documents.appendingPathComponent("Inbox", isDirectory: true), fileManager: fileManager)
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

        let recording = InboxRecording(
            id: metadata.id,
            originalFileName: metadata.originalFileName,
            storedFileName: storedFileName,
            createdAt: metadata.createdAt,
            importedAt: Date(),
            durationSeconds: metadata.durationSeconds,
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
        return try JSONDecoder().decode([InboxRecording].self, from: data)
    }

    private func ensureDirectoriesExist() throws {
        try fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
    }

    private func save(_ recordings: [InboxRecording]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(recordings)
        try data.write(to: manifestURL, options: .atomic)
    }
}
