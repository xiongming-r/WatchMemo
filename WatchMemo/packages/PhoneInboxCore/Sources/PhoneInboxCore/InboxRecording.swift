import Foundation

public struct InboxRecording: Codable, Equatable, Identifiable {
    public enum Source: String, Codable, Equatable {
        case watchConnectivity
        case simulatedImport
    }

    public enum Status: String, Codable, Equatable {
        case readyForTranscription
        case transcribingLater
    }

    public let id: UUID
    public let originalFileName: String
    public let storedFileName: String
    public let createdAt: Date
    public let importedAt: Date
    public let durationSeconds: TimeInterval
    public let source: Source
    public var status: Status
    public let fileURL: URL

    public init(
        id: UUID,
        originalFileName: String,
        storedFileName: String,
        createdAt: Date,
        importedAt: Date,
        durationSeconds: TimeInterval,
        source: Source,
        status: Status,
        fileURL: URL
    ) {
        self.id = id
        self.originalFileName = originalFileName
        self.storedFileName = storedFileName
        self.createdAt = createdAt
        self.importedAt = importedAt
        self.durationSeconds = durationSeconds
        self.source = source
        self.status = status
        self.fileURL = fileURL
    }
}

public struct InboxImportMetadata: Equatable {
    public let id: UUID
    public let originalFileName: String
    public let createdAt: Date
    public let durationSeconds: TimeInterval
    public let source: InboxRecording.Source

    public init(
        id: UUID,
        originalFileName: String,
        createdAt: Date,
        durationSeconds: TimeInterval,
        source: InboxRecording.Source
    ) {
        self.id = id
        self.originalFileName = originalFileName
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.source = source
    }
}
