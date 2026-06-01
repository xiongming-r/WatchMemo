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

    @Test("provider runtime settings default to fake provider")
    func providerRuntimeSettingsDefaultToFake() {
        let settings = ProviderRuntimeSettings.default

        #expect(settings.selectedProvider == .fake)
        #expect(settings.endpointURL == URL(string: "https://api.openai.com/v1")!)
        #expect(settings.model == "mimo-v2.5-pro")
    }

    @Test("provider runtime settings create OpenAI compatible configuration")
    func providerRuntimeSettingsCreateOpenAICompatibleConfiguration() {
        let settings = ProviderRuntimeSettings.openAICompatible(
            endpointURL: URL(string: "https://api.example.com/v1")!,
            model: "custom-audio-model"
        )

        #expect(settings.selectedProvider == .openAICompatible)
        #expect(settings.providerConfiguration.kind == .openAICompatible)
        #expect(settings.providerConfiguration.endpointURL == URL(string: "https://api.example.com/v1")!)
        #expect(settings.providerConfiguration.model == "custom-audio-model")
    }

    @Test("OpenAI compatible provider sends audio understanding chat request and parses text")
    func openAICompatibleProviderSendsAudioUnderstandingRequestAndParsesText() async throws {
        let root = try makeTemporaryDirectory()
        let audioURL = root.appendingPathComponent("sample.m4a")
        try Data("audio-bytes".utf8).write(to: audioURL)
        let client = CapturingTranscriptHTTPClient(
            response: HTTPURLResponse(
                url: URL(string: "https://api.example.com/v1/chat/completions")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!,
            data: Data(#"{"choices":[{"message":{"content":"今天会议决定先做手表录音。"}}]}"#.utf8)
        )
        let provider = OpenAICompatibleTranscriptProvider(
            configuration: .openAICompatible(
                endpointURL: URL(string: "https://api.example.com/v1")!,
                model: "mimo-v2.5-pro"
            ),
            apiKey: "test-key",
            httpClient: client,
            noteInstruction: "测试整理指令"
        )

        let transcript = try await provider.transcribe(audioFileURL: audioURL, hint: "会议记录")

        #expect(transcript == "今天会议决定先做手表录音。")
        #expect(client.capturedRequest?.httpMethod == "POST")
        #expect(client.capturedRequest?.url?.absoluteString == "https://api.example.com/v1/chat/completions")
        #expect(client.capturedRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(client.capturedRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(client.capturedBodyString)
        #expect(body.contains(#""model":"mimo-v2.5-pro""#))
        #expect(body.contains(#""type":"input_audio""#))
        #expect(body.contains(#""format":"m4a""#))
        #expect(body.contains(#""data":"YXVkaW8tYnl0ZXM=""#))
        #expect(body.contains("测试整理指令"))
        #expect(body.contains("会议记录"))
    }

    @Test("OpenAI compatible provider throws on non-success responses")
    func openAICompatibleProviderThrowsOnFailure() async throws {
        let root = try makeTemporaryDirectory()
        let audioURL = root.appendingPathComponent("sample.m4a")
        try Data("audio-bytes".utf8).write(to: audioURL)
        let client = CapturingTranscriptHTTPClient(
            response: HTTPURLResponse(
                url: URL(string: "https://api.example.com/v1/chat/completions")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!,
            data: Data(#"{"error":{"message":"bad key"}}"#.utf8)
        )
        let provider = OpenAICompatibleTranscriptProvider(
            configuration: .openAICompatible(endpointURL: URL(string: "https://api.example.com/v1")!),
            apiKey: "bad-key",
            httpClient: client
        )

        await #expect(throws: OpenAICompatibleTranscriptProviderError.self) {
            _ = try await provider.transcribe(audioFileURL: audioURL, hint: nil)
        }
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

private final class CapturingTranscriptHTTPClient: TranscriptHTTPClient {
    let response: HTTPURLResponse
    let data: Data
    private(set) var capturedRequest: URLRequest?
    private(set) var capturedBody: Data?

    var capturedBodyString: String? {
        capturedBody.flatMap { String(data: $0, encoding: .utf8) }
    }

    init(response: HTTPURLResponse, data: Data) {
        self.response = response
        self.data = data
    }

    func data(for request: URLRequest, body: Data) async throws -> (Data, HTTPURLResponse) {
        capturedRequest = request
        capturedBody = body
        return (data, response)
    }
}
