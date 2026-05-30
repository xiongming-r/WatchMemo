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

    @Test("draft store persists drafts and replaces matching recording IDs")
    func draftStorePersistsAndReplacesDrafts() throws {
        let root = try makeTemporaryDirectory()
        let recordingID = UUID(uuidString: "22222222-3333-4444-5555-666666666666")!
        let first = makeDraft(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            recordingID: recordingID,
            cleanedText: "first cleaned text"
        )
        let replacement = makeDraft(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
            recordingID: recordingID,
            cleanedText: "replacement cleaned text"
        )

        let store = TranscriptDraftStore(rootDirectory: root.appendingPathComponent("Drafts"))
        try store.save(first)
        try store.save(replacement)

        let reloadedStore = TranscriptDraftStore(rootDirectory: root.appendingPathComponent("Drafts"))
        let reloaded = try reloadedStore.loadDrafts()

        #expect(reloaded == [replacement])
    }

    @Test("provider configuration defines fake provider boundary")
    func providerConfigurationDefinesFakeBoundary() {
        let configuration = ProviderConfiguration.fake

        #expect(configuration.kind == .fake)
        #expect(configuration.displayName == "Fake local provider")
        #expect(configuration.endpointURL == nil)
        #expect(configuration.model == nil)
        #expect(configuration.commandPath == nil)
    }

    private func makeDraft(id: UUID, recordingID: UUID, cleanedText: String) -> TranscriptDraft {
        TranscriptDraft(
            id: id,
            recordingID: recordingID,
            rawText: "raw \(cleanedText)",
            cleanedText: cleanedText,
            removedFillers: ["嗯"],
            createdAt: Date(timeIntervalSince1970: 1_778_910_000),
            status: .cleaned
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TranscriptPipelineTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
