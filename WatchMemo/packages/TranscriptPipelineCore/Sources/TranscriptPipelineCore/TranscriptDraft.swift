import Foundation

public struct TranscriptDraft: Codable, Equatable, Identifiable {
    public enum Status: String, Codable, Equatable {
        case raw
        case cleaned
    }

    public let id: UUID
    public let recordingID: UUID
    public let rawText: String
    public let cleanedText: String
    public let removedFillers: [String]
    public let createdAt: Date
    public let status: Status
    public let structuredNote: StructuredTranscriptNote?

    public init(
        id: UUID,
        recordingID: UUID,
        rawText: String,
        cleanedText: String,
        removedFillers: [String],
        createdAt: Date,
        status: Status,
        structuredNote: StructuredTranscriptNote? = nil
    ) {
        self.id = id
        self.recordingID = recordingID
        self.rawText = rawText
        self.cleanedText = cleanedText
        self.removedFillers = removedFillers
        self.createdAt = createdAt
        self.status = status
        self.structuredNote = structuredNote
    }
}

public struct TranscriptCleanupResult: Equatable {
    public let originalText: String
    public let cleanedText: String
    public let removedFillers: [String]

    public init(originalText: String, cleanedText: String, removedFillers: [String]) {
        self.originalText = originalText
        self.cleanedText = cleanedText
        self.removedFillers = removedFillers
    }
}
