import Foundation

public enum LongAudioProcessingDecision: Equatable, Sendable {
    case singlePass
    case segmented(segmentDurationSeconds: TimeInterval, overlapSeconds: TimeInterval)
}

public struct LongAudioProcessingStrategy: Equatable, Sendable {
    public static let `default` = LongAudioProcessingStrategy(
        durationThresholdSeconds: 10 * 60,
        byteThreshold: 5 * 1_024 * 1_024,
        segmentDurationSeconds: 5 * 60,
        overlapSeconds: 15
    )

    public let durationThresholdSeconds: TimeInterval
    public let byteThreshold: Int64
    public let segmentDurationSeconds: TimeInterval
    public let overlapSeconds: TimeInterval

    public init(
        durationThresholdSeconds: TimeInterval,
        byteThreshold: Int64,
        segmentDurationSeconds: TimeInterval,
        overlapSeconds: TimeInterval
    ) {
        self.durationThresholdSeconds = durationThresholdSeconds
        self.byteThreshold = byteThreshold
        self.segmentDurationSeconds = segmentDurationSeconds
        self.overlapSeconds = overlapSeconds
    }

    public func decision(durationSeconds: TimeInterval, audioByteCount: Int64?) -> LongAudioProcessingDecision {
        if durationSeconds > durationThresholdSeconds || (audioByteCount ?? 0) > byteThreshold {
            return .segmented(
                segmentDurationSeconds: segmentDurationSeconds,
                overlapSeconds: overlapSeconds
            )
        }

        return .singlePass
    }
}

public struct AudioSegment: Equatable, Identifiable, Sendable {
    public let id: Int
    public let index: Int
    public let startSeconds: TimeInterval
    public let endSeconds: TimeInterval

    public var durationSeconds: TimeInterval {
        endSeconds - startSeconds
    }

    public init(index: Int, startSeconds: TimeInterval, endSeconds: TimeInterval) {
        self.id = index
        self.index = index
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }
}

public struct AudioSegmentPlan: Equatable, Sendable {
    public let segments: [AudioSegment]

    public static func make(
        durationSeconds: TimeInterval,
        segmentDurationSeconds: TimeInterval,
        overlapSeconds: TimeInterval
    ) -> AudioSegmentPlan {
        guard durationSeconds > 0, segmentDurationSeconds > 0 else {
            return AudioSegmentPlan(segments: [])
        }

        let safeOverlap = min(max(overlapSeconds, 0), max(segmentDurationSeconds - 1, 0))
        let step = segmentDurationSeconds - safeOverlap
        var segments: [AudioSegment] = []
        var index = 0
        var start: TimeInterval = 0

        while start < durationSeconds {
            let end = min(start + segmentDurationSeconds, durationSeconds)
            segments.append(AudioSegment(index: index, startSeconds: start, endSeconds: end))

            if end >= durationSeconds {
                break
            }

            index += 1
            start += step
        }

        return AudioSegmentPlan(segments: segments)
    }
}
