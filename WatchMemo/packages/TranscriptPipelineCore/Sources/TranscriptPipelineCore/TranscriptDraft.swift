import Foundation

public struct TranscriptDraft: Codable, Equatable, Identifiable {
    public enum Status: String, Codable, Equatable {
        case raw
        case cleaned
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case recordingID
        case rawText
        case cleanedText
        case removedFillers
        case createdAt
        case status
        case structuredNote
        case qualityMetrics
    }

    public let id: UUID
    public let recordingID: UUID
    public let rawText: String
    public let cleanedText: String
    public let removedFillers: [String]
    public let createdAt: Date
    public let status: Status
    public let structuredNote: StructuredTranscriptNote?
    public let qualityMetrics: TranscriptQualityMetrics?

    public init(
        id: UUID,
        recordingID: UUID,
        rawText: String,
        cleanedText: String,
        removedFillers: [String],
        createdAt: Date,
        status: Status,
        structuredNote: StructuredTranscriptNote? = nil,
        qualityMetrics: TranscriptQualityMetrics? = nil
    ) {
        self.id = id
        self.recordingID = recordingID
        self.rawText = rawText
        self.cleanedText = cleanedText
        self.removedFillers = removedFillers
        self.createdAt = createdAt
        self.status = status
        self.structuredNote = structuredNote
        self.qualityMetrics = qualityMetrics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(UUID.self, forKey: .id)
        self.recordingID = try container.decode(UUID.self, forKey: .recordingID)
        self.rawText = try container.decode(String.self, forKey: .rawText)
        self.cleanedText = try container.decode(String.self, forKey: .cleanedText)
        self.removedFillers = try container.decode([String].self, forKey: .removedFillers)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.status = try container.decode(Status.self, forKey: .status)
        self.structuredNote = try container.decodeIfPresent(StructuredTranscriptNote.self, forKey: .structuredNote)
        self.qualityMetrics = try container.decodeIfPresent(TranscriptQualityMetrics.self, forKey: .qualityMetrics)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(recordingID, forKey: .recordingID)
        try container.encode(rawText, forKey: .rawText)
        try container.encode(cleanedText, forKey: .cleanedText)
        try container.encode(removedFillers, forKey: .removedFillers)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(structuredNote, forKey: .structuredNote)
        try container.encodeIfPresent(qualityMetrics, forKey: .qualityMetrics)
    }
}

public struct TranscriptQualityMetrics: Codable, Equatable {
    public let rawCharacterCount: Int
    public let cleanedCharacterCount: Int
    public let compressionRatio: Double?
    public let removedFillerCount: Int
    public let segmentCount: Int
    public let usedSegmentedProcessing: Bool
    public let speakerLabels: [String]
    public let estimatedSpeakerCount: Int
    public let hasSpeakerLabels: Bool

    public init(
        rawCharacterCount: Int,
        cleanedCharacterCount: Int,
        compressionRatio: Double?,
        removedFillerCount: Int,
        segmentCount: Int,
        usedSegmentedProcessing: Bool,
        speakerLabels: [String]
    ) {
        self.rawCharacterCount = rawCharacterCount
        self.cleanedCharacterCount = cleanedCharacterCount
        self.compressionRatio = compressionRatio
        self.removedFillerCount = removedFillerCount
        self.segmentCount = segmentCount
        self.usedSegmentedProcessing = usedSegmentedProcessing
        self.speakerLabels = speakerLabels
        self.estimatedSpeakerCount = speakerLabels.count
        self.hasSpeakerLabels = !speakerLabels.isEmpty
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
