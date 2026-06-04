import Foundation

public struct InboxRecording: Codable, Equatable, Identifiable {
    public enum Source: String, Codable, Equatable {
        case watchConnectivity
        case simulatedImport
    }

    public enum Status: String, Codable, Equatable {
        case readyForTranscription
        case transcribing
        case draftReady
        case transcriptionFailed
        case transcribingLater
    }

    public let id: UUID
    public let originalFileName: String
    public let storedFileName: String
    public let createdAt: Date
    public let importedAt: Date
    public let durationSeconds: TimeInterval
    public let audioByteCount: Int64?
    public let source: Source
    public var status: Status
    public var transcriptionErrorMessage: String?
    public var transcriptionAttemptCount: Int
    public var lastTranscriptionAttemptAt: Date?
    public var lastTranscriptionDurationSeconds: TimeInterval?
    public var isArchived: Bool
    public var archivedAt: Date?
    public let fileURL: URL

    public init(
        id: UUID,
        originalFileName: String,
        storedFileName: String,
        createdAt: Date,
        importedAt: Date,
        durationSeconds: TimeInterval,
        audioByteCount: Int64? = nil,
        source: Source,
        status: Status,
        transcriptionErrorMessage: String? = nil,
        transcriptionAttemptCount: Int = 0,
        lastTranscriptionAttemptAt: Date? = nil,
        lastTranscriptionDurationSeconds: TimeInterval? = nil,
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        fileURL: URL
    ) {
        self.id = id
        self.originalFileName = originalFileName
        self.storedFileName = storedFileName
        self.createdAt = createdAt
        self.importedAt = importedAt
        self.durationSeconds = durationSeconds
        self.audioByteCount = audioByteCount
        self.source = source
        self.status = status
        self.transcriptionErrorMessage = transcriptionErrorMessage
        self.transcriptionAttemptCount = transcriptionAttemptCount
        self.lastTranscriptionAttemptAt = lastTranscriptionAttemptAt
        self.lastTranscriptionDurationSeconds = lastTranscriptionDurationSeconds
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.fileURL = fileURL
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case originalFileName
        case storedFileName
        case createdAt
        case importedAt
        case durationSeconds
        case audioByteCount
        case source
        case status
        case transcriptionErrorMessage
        case transcriptionAttemptCount
        case lastTranscriptionAttemptAt
        case lastTranscriptionDurationSeconds
        case isArchived
        case archivedAt
        case fileURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        originalFileName = try container.decode(String.self, forKey: .originalFileName)
        storedFileName = try container.decode(String.self, forKey: .storedFileName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        importedAt = try container.decode(Date.self, forKey: .importedAt)
        durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        audioByteCount = try container.decodeIfPresent(Int64.self, forKey: .audioByteCount)
        source = try container.decode(Source.self, forKey: .source)
        status = try container.decode(Status.self, forKey: .status)
        transcriptionErrorMessage = try container.decodeIfPresent(String.self, forKey: .transcriptionErrorMessage)
        transcriptionAttemptCount = try container.decodeIfPresent(Int.self, forKey: .transcriptionAttemptCount) ?? 0
        lastTranscriptionAttemptAt = try container.decodeIfPresent(Date.self, forKey: .lastTranscriptionAttemptAt)
        lastTranscriptionDurationSeconds = try container.decodeIfPresent(
            TimeInterval.self,
            forKey: .lastTranscriptionDurationSeconds
        )
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        fileURL = try container.decode(URL.self, forKey: .fileURL)
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
