import AVFoundation
import Foundation

@MainActor
final class PhoneInboxViewModel: ObservableObject {
    @Published private(set) var recordings: [InboxRecording] = []
    @Published private(set) var transcriptDrafts: [InboxRecording.ID: TranscriptDraft] = [:]
    @Published private(set) var processingTranscriptIDs: Set<InboxRecording.ID> = []
    @Published private(set) var providerSettings: ProviderRuntimeSettings
    @Published private(set) var obsidianSettings: ObsidianExportSettings
    @Published private(set) var hasSavedAPIKey: Bool
    @Published private(set) var statusText = "Loading inbox"

    private let store: PhoneInboxStore
    private let draftStore: TranscriptDraftStore
    private let providerSettingsStore: ProviderSettingsStore
    private let obsidianSettingsStore: ObsidianSettingsStore
    private let obsidianURLBuilder: ObsidianExportURLBuilder
    private let apiKeyStore: APIKeyStore
    private let receiver: PhoneConnectivityReceiver

    init(
        store: PhoneInboxStore = PhoneInboxStore(),
        draftStore: TranscriptDraftStore = TranscriptDraftStore(),
        providerSettingsStore: ProviderSettingsStore = ProviderSettingsStore(),
        obsidianSettingsStore: ObsidianSettingsStore = ObsidianSettingsStore(),
        obsidianURLBuilder: ObsidianExportURLBuilder = ObsidianExportURLBuilder(),
        apiKeyStore: APIKeyStore = APIKeyStore()
    ) {
        self.store = store
        self.draftStore = draftStore
        self.providerSettingsStore = providerSettingsStore
        self.obsidianSettingsStore = obsidianSettingsStore
        self.obsidianURLBuilder = obsidianURLBuilder
        self.apiKeyStore = apiKeyStore
        self.providerSettings = providerSettingsStore.load()
        self.obsidianSettings = obsidianSettingsStore.load()
        self.hasSavedAPIKey = apiKeyStore.hasKey()
        self.receiver = PhoneConnectivityReceiver(store: store)

        receiver.onImported = { [weak self] _ in
            self?.reload(status: "Received watch recording")
        }
        receiver.onStatusChange = { [weak self] status in
            self?.statusText = status
        }

        reload(status: nil)
        loadDrafts()
    }

    func start() {
        receiver.start()
    }

    func processTranscript(for recording: InboxRecording) async {
        guard !processingTranscriptIDs.contains(recording.id) else {
            return
        }

        processingTranscriptIDs.insert(recording.id)
        defer {
            processingTranscriptIDs.remove(recording.id)
        }

        do {
            let transcriptPipeline = try makeTranscriptPipeline()
            let draft = try await transcriptPipeline.makeDraft(
                recordingID: recording.id,
                audioFileURL: recording.fileURL,
                hint: recording.originalFileName
            )
            try draftStore.save(draft)
            transcriptDrafts[recording.id] = draft
            statusText = "Draft ready"
        } catch {
            statusText = "Draft failed: \(error.localizedDescription)"
        }
    }

    func saveProviderSettings(_ settings: ProviderRuntimeSettings, apiKey: String) throws {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            try apiKeyStore.save(trimmedKey)
        }

        try providerSettingsStore.save(settings)
        providerSettings = settings
        hasSavedAPIKey = apiKeyStore.hasKey()
        statusText = settings.selectedProvider == .openAICompatible
            ? "Audio understanding provider selected"
            : "Fake provider selected"
    }

    func deleteAPIKey() throws {
        try apiKeyStore.delete()
        hasSavedAPIKey = apiKeyStore.hasKey()
    }

    func saveObsidianSettings(_ settings: ObsidianExportSettings) throws {
        try obsidianSettingsStore.save(settings)
        obsidianSettings = settings
        statusText = "Obsidian settings saved"
    }

    func makeObsidianExportURL(for recording: InboxRecording) throws -> URL {
        guard let draft = transcriptDrafts[recording.id] else {
            throw ObsidianAppExportError.missingDraft
        }

        let payload = ObsidianNotePayload(
            title: draft.structuredNote?.title ?? recording.originalFileName,
            markdown: draft.markdownText,
            createdAt: recording.createdAt
        )

        return try obsidianURLBuilder.makeNewNoteURL(
            payload: payload,
            settings: obsidianSettings
        )
    }

    func markObsidianExportResult(opened: Bool) {
        statusText = opened
            ? "Opened Obsidian export"
            : "Could not open Obsidian"
    }

    func markObsidianURICopied() {
        statusText = "Obsidian URL copied"
    }

    func markLongObsidianNoteCopied(_ error: ObsidianExportError) {
        statusText = "\(error.localizedDescription). Markdown copied instead."
    }

    func markObsidianExportFailed(_ error: Error) {
        statusText = "Obsidian export failed: \(error.localizedDescription)"
    }

#if DEBUG
    func importSampleRecording() {
        statusText = "Generating simulated speech"

        Task {
            do {
                let sample = try await SampleAudioGenerator.makeSample()
                _ = try store.importRecording(
                    fileURL: sample.fileURL,
                    metadata: InboxImportMetadata(
                        id: UUID(),
                        originalFileName: sample.fileURL.lastPathComponent,
                        createdAt: Date(),
                        durationSeconds: sample.duration,
                        source: .simulatedImport
                    )
                )
                reload(status: "Imported simulated speech recording")
            } catch {
                statusText = "Simulated import failed: \(error.localizedDescription)"
            }
        }
    }
#endif

    private func reload(status: String?) {
        do {
            recordings = try store.loadRecordings()
            if let status {
                statusText = status
            } else if recordings.isEmpty {
                statusText = "Waiting for watch"
            } else {
                statusText = "\(recordings.count) recording\(recordings.count == 1 ? "" : "s") in inbox"
            }
        } catch {
            statusText = "Inbox load failed: \(error.localizedDescription)"
        }
    }

    private func loadDrafts() {
        do {
            transcriptDrafts = try draftStore.loadDrafts().reduce(into: [:]) { drafts, draft in
                drafts[draft.recordingID] = draft
            }
        } catch {
            statusText = "Draft load failed: \(error.localizedDescription)"
        }
    }

    private func makeTranscriptPipeline() throws -> TranscriptPipeline {
        let provider: any TranscriptProvider

        switch providerSettings.selectedProvider {
        case .fake:
            provider = FakeTranscriptProvider()
        case .openAICompatible:
            guard let apiKey = try apiKeyStore.load(), !apiKey.isEmpty else {
                throw ProviderSelectionError.missingAPIKey
            }

            provider = OpenAICompatibleTranscriptProvider(
                configuration: providerSettings.providerConfiguration,
                apiKey: apiKey
            )
        }

        return TranscriptPipeline(
            provider: provider,
            cleaner: providerSettings.selectedProvider == .openAICompatible
                ? PassthroughTranscriptCleaner()
                : ConservativeTranscriptCleaner()
        )
    }
}

private extension TranscriptDraft {
    var markdownText: String {
        structuredNote?.markdown ?? cleanedText
    }
}

private enum ObsidianAppExportError: LocalizedError {
    case missingDraft

    var errorDescription: String? {
        switch self {
        case .missingDraft:
            return "Create a draft before exporting to Obsidian"
        }
    }
}

private enum ProviderSelectionError: LocalizedError {
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI-compatible provider needs an API key"
        }
    }
}

#if DEBUG
private enum SampleAudioGenerator {
    static func makeSample() async throws -> (fileURL: URL, duration: TimeInterval) {
        let spokenText = "测试录音。今天下午三点验证手表录音功能，重点检查音频上传和 AI 整理结果是否准确。"
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("watchmemo-debug-speech-\(UUID().uuidString).m4a")

        return try await withCheckedThrowingContinuation { continuation in
            let synthesizer = AVSpeechSynthesizer()
            let utterance = AVSpeechUtterance(string: spokenText)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
            utterance.volume = 1.0

            var audioFile: AVAudioFile?
            var totalFrames: AVAudioFramePosition = 0
            var didResume = false

            func resumeOnce(_ result: Result<(fileURL: URL, duration: TimeInterval), Error>) {
                guard !didResume else {
                    return
                }

                didResume = true
                continuation.resume(with: result)
            }

            synthesizer.write(utterance) { [synthesizer] buffer in
                _ = synthesizer

                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    resumeOnce(.failure(SampleAudioGeneratorError.unsupportedBufferFormat))
                    return
                }

                guard pcmBuffer.frameLength > 0 else {
                    guard let audioFile, totalFrames > 0 else {
                        resumeOnce(.failure(SampleAudioGeneratorError.emptyAudio))
                        return
                    }

                    let duration = Double(totalFrames) / audioFile.processingFormat.sampleRate
                    resumeOnce(.success((fileURL: fileURL, duration: duration)))
                    return
                }

                do {
                    if audioFile == nil {
                        let outputSettings: [String: Any] = [
                            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: pcmBuffer.format.sampleRate,
                            AVNumberOfChannelsKey: Int(pcmBuffer.format.channelCount),
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                        ]
                        audioFile = try AVAudioFile(
                            forWriting: fileURL,
                            settings: outputSettings,
                            commonFormat: pcmBuffer.format.commonFormat,
                            interleaved: pcmBuffer.format.isInterleaved
                        )
                    }

                    try audioFile?.write(from: pcmBuffer)
                    totalFrames += AVAudioFramePosition(pcmBuffer.frameLength)
                } catch {
                    resumeOnce(.failure(error))
                }
            }
        }
    }
}

private enum SampleAudioGeneratorError: LocalizedError {
    case unsupportedBufferFormat
    case emptyAudio

    var errorDescription: String? {
        switch self {
        case .unsupportedBufferFormat:
            return "Speech synthesizer returned an unsupported audio buffer"
        case .emptyAudio:
            return "Speech synthesizer did not produce audio"
        }
    }
}
#endif
