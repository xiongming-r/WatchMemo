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
        #expect(draft.structuredNote?.title == "Record the pricing idea")
        #expect(draft.structuredNote?.markdown.contains("## 正文") == true)
        #expect(draft.qualityMetrics?.rawCharacterCount == draft.rawText.count)
        #expect(draft.qualityMetrics?.cleanedCharacterCount == draft.cleanedText.count)
        #expect(draft.qualityMetrics?.removedFillerCount == 2)
        #expect(draft.qualityMetrics?.segmentCount == 1)
        #expect(draft.qualityMetrics?.usedSegmentedProcessing == false)
        #expect(draft.qualityMetrics?.hasSpeakerLabels == false)
    }

    @Test("pipeline merges segment transcripts in order")
    func pipelineMergesSegmentTranscriptsInOrder() async throws {
        let provider = MappingTranscriptProvider(textByFileName: [
            "segment-0.m4a": "第一段：讨论手表录音。",
            "segment-1.m4a": "第二段：确认 iPhone 接收。",
            "segment-2.m4a": "第三段：安排长录音测试。"
        ])
        let pipeline = TranscriptPipeline(
            provider: provider,
            cleaner: PassthroughTranscriptCleaner(),
            now: { Date(timeIntervalSince1970: 1_778_930_000) }
        )
        let recordingID = UUID(uuidString: "88888888-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!
        let root = try makeTemporaryDirectory()
        let segmentURLs = [
            root.appendingPathComponent("segment-0.m4a"),
            root.appendingPathComponent("segment-1.m4a"),
            root.appendingPathComponent("segment-2.m4a")
        ]

        let draft = try await pipeline.makeDraftFromSegments(
            recordingID: recordingID,
            segmentFileURLs: segmentURLs,
            hint: "长录音"
        )

        #expect(draft.recordingID == recordingID)
        #expect(draft.rawText.contains("第一段：讨论手表录音。"))
        #expect(draft.rawText.contains("第二段：确认 iPhone 接收。"))
        #expect(draft.rawText.contains("第三段：安排长录音测试。"))
        #expect(draft.cleanedText == draft.rawText)
        #expect(draft.structuredNote?.markdown.contains("## 正文") == true)
        #expect(draft.qualityMetrics?.segmentCount == 3)
        #expect(draft.qualityMetrics?.usedSegmentedProcessing == true)
    }

    @Test("pipeline detects lightweight speaker labels")
    func pipelineDetectsSpeakerLabels() async throws {
        let provider = FakeTranscriptProvider(
            fixedText: """
            说话人 A：我们先确认手表录音是否稳定。
            说话人 B：我负责今晚整理长录音测试结果。
            说话人 A：好的，明天再看 Obsidian 导出。
            """
        )
        let pipeline = TranscriptPipeline(
            provider: provider,
            cleaner: PassthroughTranscriptCleaner(),
            now: { Date(timeIntervalSince1970: 1_778_940_000) }
        )

        let draft = try await pipeline.makeDraft(
            recordingID: UUID(uuidString: "77777777-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!,
            audioFileURL: URL(fileURLWithPath: "/tmp/speakers.m4a")
        )

        #expect(draft.qualityMetrics?.speakerLabels == ["说话人 A", "说话人 B"])
        #expect(draft.qualityMetrics?.estimatedSpeakerCount == 2)
        #expect(draft.qualityMetrics?.hasSpeakerLabels == true)
    }

    @Test("pipeline detects markdown speaker labels with descriptions")
    func pipelineDetectsMarkdownSpeakerLabelsWithDescriptions() async throws {
        let provider = FakeTranscriptProvider(
            fixedText: """
            **说话人A（女）：** 这个一定很香吧。
            **说话人B（男）：** 我在直播里看到这个，买来给你们尝尝。
            """
        )
        let pipeline = TranscriptPipeline(
            provider: provider,
            cleaner: PassthroughTranscriptCleaner(),
            now: { Date(timeIntervalSince1970: 1_778_945_000) }
        )

        let draft = try await pipeline.makeDraft(
            recordingID: UUID(uuidString: "66666666-AAAA-BBBB-CCCC-DDDDDDDDDDDD")!,
            audioFileURL: URL(fileURLWithPath: "/tmp/markdown-speakers.m4a")
        )

        #expect(draft.qualityMetrics?.speakerLabels == ["说话人A（女）", "说话人B（男）"])
        #expect(draft.qualityMetrics?.estimatedSpeakerCount == 2)
    }

    @Test("note formatter parses structured markdown sections")
    func noteFormatterParsesStructuredMarkdownSections() {
        let formatter = TranscriptNoteFormatter()
        let note = formatter.format(
            text: """
            # 茶歇试吃讨论

            ## 摘要
            两位说话人讨论试吃零食、来源和口味判断。

            ## 对话整理
            **说话人A（女）：** 这个一定很香吧。
            **说话人B（男）：** 我在直播里看到这个，买来给你们尝尝。

            ## 关键结论
            - 这段录音属于轻松试吃交流，没有正式任务。

            ## 待办
            - [ ] 下次记录时靠近声源。

            ## 标签
            #试吃 #对话
            """,
            createdAt: Date(timeIntervalSince1970: 1_778_945_000)
        )

        #expect(note.title == "茶歇试吃讨论")
        #expect(note.summary == "两位说话人讨论试吃零食、来源和口味判断。")
        #expect(note.body.contains("说话人A（女）"))
        #expect(note.body.contains("这段录音属于轻松试吃交流"))
        #expect(note.actionItems == ["下次记录时靠近声源。"])
        #expect(note.tags == ["试吃", "对话"])
        #expect(note.markdown.contains("## 摘要\n两位说话人讨论试吃零食、来源和口味判断。"))
    }

    @Test("note formatter creates title summary action items tags and markdown")
    func noteFormatterCreatesStructuredNote() {
        let formatter = TranscriptNoteFormatter()
        let note = formatter.format(
            text: """
            今天讨论 WatchMemo 真机验证，确认手表录音可以同步到手机。
            待办：补充失败重试按钮。
            标签：手表录音, MVP
            """,
            createdAt: Date(timeIntervalSince1970: 1_778_920_000)
        )

        #expect(note.title == "今天讨论 WatchMemo 真机验证")
        #expect(note.summary == "今天讨论 WatchMemo 真机验证，确认手表录音可以同步到手机。")
        #expect(note.actionItems == ["补充失败重试按钮。"])
        #expect(note.tags == ["手表录音", "MVP"])
        #expect(note.markdown.contains("# 今天讨论 WatchMemo 真机验证"))
        #expect(note.markdown.contains("- [ ] 补充失败重试按钮。"))
        #expect(note.markdown.contains("#手表录音 #MVP"))
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

    @Test("draft store decodes legacy drafts without structured notes")
    func draftStoreDecodesLegacyDraftsWithoutStructuredNotes() throws {
        let root = try makeTemporaryDirectory().appendingPathComponent("Drafts")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data(
            """
            [
              {
                "id": "AAAAAAAA-0000-0000-0000-000000000003",
                "recordingID": "22222222-3333-4444-5555-666666666666",
                "rawText": "raw text",
                "cleanedText": "cleaned text",
                "removedFillers": [],
                "createdAt": 1778920000,
                "status": "cleaned"
              }
            ]
            """.utf8
        ).write(to: root.appendingPathComponent("transcript-drafts.json"))

        let drafts = try TranscriptDraftStore(rootDirectory: root).loadDrafts()

        #expect(drafts.count == 1)
        #expect(drafts[0].structuredNote == nil)
        #expect(drafts[0].qualityMetrics == nil)
        #expect(drafts[0].cleanedText == "cleaned text")
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
        #expect(settings.model == "mimo-v2.5")
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
                model: "mimo-v2.5"
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
        #expect(body.contains(#""model":"mimo-v2.5""#))
        #expect(body.contains(#""type":"input_audio""#))
        #expect(!body.contains(#""format":"m4a""#))
        #expect(body.contains(#""data":"data:audio/m4a;base64,YXVkaW8tYnl0ZXM=""#))
        #expect(body.contains("测试整理指令"))
        #expect(body.contains("会议记录"))
    }

    @Test("OpenAI compatible provider asks model not to invent content")
    func openAICompatibleProviderAsksModelNotToInventContent() async throws {
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
            data: Data(#"{"choices":[{"message":{"content":"无法从音频中识别出明确人声内容。"}}]}"#.utf8)
        )
        let provider = OpenAICompatibleTranscriptProvider(
            configuration: .openAICompatible(endpointURL: URL(string: "https://api.example.com/v1")!),
            apiKey: "test-key",
            httpClient: client
        )

        _ = try await provider.transcribe(audioFileURL: audioURL, hint: "debug sample")

        let body = try #require(client.capturedBodyString)
        #expect(body.contains("不要编造"))
        #expect(body.contains("无法从音频中识别出明确人声内容"))
        #expect(body.contains("说话人 A"))
        #expect(body.contains("## 摘要"))
        #expect(body.contains("## 关键结论"))
        #expect(body.contains("## 待办"))
        #expect(body.contains("不要强行标注"))
        #expect(body.contains("去除语气词"))
    }

    @Test("OpenAI compatible provider parses reasoning content when message content is empty")
    func openAICompatibleProviderParsesReasoningContentFallback() async throws {
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
            data: Data(#"{"choices":[{"message":{"content":"","reasoning_content":"会议结论：先验证手表录音到 iPhone。"}}]}"#.utf8)
        )
        let provider = OpenAICompatibleTranscriptProvider(
            configuration: .openAICompatible(endpointURL: URL(string: "https://api.example.com/v1")!),
            apiKey: "test-key",
            httpClient: client
        )

        let transcript = try await provider.transcribe(audioFileURL: audioURL, hint: nil)

        #expect(transcript == "会议结论：先验证手表录音到 iPhone。")
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
            status: .cleaned,
            structuredNote: TranscriptNoteFormatter().format(
                text: cleanedText,
                createdAt: Date(timeIntervalSince1970: 1_778_910_000)
            )
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

private struct MappingTranscriptProvider: TranscriptProvider {
    let textByFileName: [String: String]

    func transcribe(audioFileURL: URL, hint: String?) async throws -> String {
        textByFileName[audioFileURL.lastPathComponent] ?? ""
    }
}
