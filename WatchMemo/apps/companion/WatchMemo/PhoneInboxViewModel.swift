import AVFoundation
import Foundation

@MainActor
final class PhoneInboxViewModel: ObservableObject {
    @Published private(set) var recordings: [InboxRecording] = []
    @Published private(set) var transcriptDrafts: [InboxRecording.ID: TranscriptDraft] = [:]
    @Published private(set) var processingTranscriptIDs: Set<InboxRecording.ID> = []
    @Published private(set) var statusText = "Loading inbox"

    private let store: PhoneInboxStore
    private let draftStore: TranscriptDraftStore
    private let receiver: PhoneConnectivityReceiver
    private let transcriptPipeline: TranscriptPipeline

    init(
        store: PhoneInboxStore = PhoneInboxStore(),
        draftStore: TranscriptDraftStore = TranscriptDraftStore(),
        transcriptPipeline: TranscriptPipeline = TranscriptPipeline(
            provider: FakeTranscriptProvider(),
            cleaner: ConservativeTranscriptCleaner()
        )
    ) {
        self.store = store
        self.draftStore = draftStore
        self.transcriptPipeline = transcriptPipeline
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
            .appendingPathComponent("watchmemo-sample-\(UUID().uuidString).caf")
        let audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        try audioFile.write(from: buffer)
        return (fileURL, duration)
    }
}
#endif
