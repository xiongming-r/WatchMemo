import Foundation

public final class TranscriptDraftStore {
    private let fileManager: FileManager
    private let rootDirectory: URL
    private let manifestURL: URL

    public init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
        self.manifestURL = rootDirectory.appendingPathComponent("transcript-drafts.json")
    }

    public convenience init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.init(
            rootDirectory: documents.appendingPathComponent("TranscriptDrafts", isDirectory: true),
            fileManager: fileManager
        )
    }

    public func save(_ draft: TranscriptDraft) throws {
        try ensureDirectoryExists()

        var drafts = try loadDrafts()
        drafts.removeAll { $0.recordingID == draft.recordingID }
        drafts.insert(draft, at: 0)
        try write(drafts)
    }

    public func loadDrafts() throws -> [TranscriptDraft] {
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return []
        }

        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode([TranscriptDraft].self, from: data)
    }

    private func ensureDirectoryExists() throws {
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    private func write(_ drafts: [TranscriptDraft]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(drafts)
        try data.write(to: manifestURL, options: .atomic)
    }
}
