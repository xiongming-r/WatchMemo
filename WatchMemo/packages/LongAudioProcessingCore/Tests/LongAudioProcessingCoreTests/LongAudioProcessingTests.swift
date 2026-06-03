import Testing
@testable import LongAudioProcessingCore

@Suite("Long audio processing")
struct LongAudioProcessingTests {
    @Test("keeps short small recordings as single pass")
    func shortSmallRecordingUsesSinglePass() {
        let decision = LongAudioProcessingStrategy.default.decision(
            durationSeconds: 9 * 60,
            audioByteCount: 4 * 1_024 * 1_024
        )

        #expect(decision == .singlePass)
    }

    @Test("splits long recordings")
    func longRecordingUsesSegments() {
        let decision = LongAudioProcessingStrategy.default.decision(
            durationSeconds: 11 * 60,
            audioByteCount: 2 * 1_024 * 1_024
        )

        #expect(decision == .segmented(segmentDurationSeconds: 300, overlapSeconds: 15))
    }

    @Test("splits large recordings")
    func largeRecordingUsesSegments() {
        let decision = LongAudioProcessingStrategy.default.decision(
            durationSeconds: 2 * 60,
            audioByteCount: 6 * 1_024 * 1_024
        )

        #expect(decision == .segmented(segmentDurationSeconds: 300, overlapSeconds: 15))
    }

    @Test("plans overlapped segments in order")
    func plansOverlappedSegments() {
        let plan = AudioSegmentPlan.make(
            durationSeconds: 12 * 60,
            segmentDurationSeconds: 300,
            overlapSeconds: 15
        )

        #expect(plan.segments.map(\.index) == [0, 1, 2])
        #expect(plan.segments[0].startSeconds == 0)
        #expect(plan.segments[0].endSeconds == 300)
        #expect(plan.segments[1].startSeconds == 285)
        #expect(plan.segments[1].endSeconds == 585)
        #expect(plan.segments[2].startSeconds == 570)
        #expect(plan.segments[2].endSeconds == 720)
    }
}
