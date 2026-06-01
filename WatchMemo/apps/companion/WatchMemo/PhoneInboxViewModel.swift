import AVFoundation
import Foundation

@MainActor
final class PhoneInboxViewModel: ObservableObject {
    @Published private(set) var recordings: [InboxRecording] = []
    @Published private(set) var transcriptDrafts: [InboxRecording.ID: TranscriptDraft] = [:]
    @Published private(set) var processingTranscriptIDs: Set<InboxRecording.ID> = []
    @Published private(set) var providerSettings: ProviderRuntimeSettings
    @Published private(set) var hasSavedAPIKey: Bool
    @Published private(set) var statusText = "Loading inbox"

    private let store: PhoneInboxStore
    private let draftStore: TranscriptDraftStore
    private let providerSettingsStore: ProviderSettingsStore
    private let apiKeyStore: APIKeyStore
    private let receiver: PhoneConnectivityReceiver

    init(
        store: PhoneInboxStore = PhoneInboxStore(),
        draftStore: TranscriptDraftStore = TranscriptDraftStore(),
        providerSettingsStore: ProviderSettingsStore = ProviderSettingsStore(),
        apiKeyStore: APIKeyStore = APIKeyStore()
    ) {
        self.store = store
        self.draftStore = draftStore
        self.providerSettingsStore = providerSettingsStore
        self.apiKeyStore = apiKeyStore
        self.providerSettings = providerSettingsStore.load()
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

#if DEBUG
    func importSampleRecording() {
        do {
            let sample = try SampleAudioGenerator.makeSample()
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
            reload(status: "Imported simulated recording")
        } catch {
            statusText = "Simulated import failed: \(error.localizedDescription)"
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
    static func makeSample() throws -> (fileURL: URL, duration: TimeInterval) {
        let duration: TimeInterval = 0.8
        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            channel[frame] = Float(sin(2.0 * Double.pi * 440.0 * time) * 0.18)
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("watchmemo-sample-\(UUID().uuidString).m4a")
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        let audioFile = try AVAudioFile(forWriting: fileURL, settings: outputSettings)
        try audioFile.write(from: buffer)
        return (fileURL, duration)
    }
}
#endif
