import Foundation
import Testing
@testable import TranscriptPipelineCore

@Suite("Transcript pipeline")
struct TranscriptPipelineTests {
    @Test("cleaner removes common filler words while keeping content")
    func cleanerRemovesFillers() {
        let cleaner = ConservativeTranscriptCleaner()
        let result = cleaner.clean("嗯 那个 今天会议就是决定先做手表录音, 呃 下周验证同步。")

        #expect(result.cleanedText == "今天会议决定先做手表录音, 下周验证同步。")
        #expect(result.removedFillers == ["嗯", "那个", "就是", "呃"])
        #expect(result.originalText.contains("今天会议"))
    }

    @Test("pipeline keeps raw text and cleaned text in one draft")
    func pipelineCreatesDraft() async throws {
        let provider = FakeTranscriptProvider(
            fixedText: "um record the pricing idea, you know, make it easier to review later."
        )
        let pipeline = TranscriptPipeline(
            provider: provider,
            cleaner: ConservativeTranscriptCleaner(),
            now: { Date(timeIntervalSince1970: 1_778_900_000) }
        )
        let recordingID = UUID(uuidString: "99999999-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!

        let draft = try await pipeline.makeDraft(
            recordingID: recordingID,
            audioFileURL: URL(fileURLWithPath: "/tmp/sample.m4a"),
            hint: "pricing idea"
        )

        #expect(draft.recordingID == recordingID)
        #expect(draft.rawText == "um record the pricing idea, you know, make it easier to review later.")
        #expect(draft.cleanedText == "record the pricing idea, make it easier to review later.")
        #expect(draft.status == .cleaned)
    }
}
