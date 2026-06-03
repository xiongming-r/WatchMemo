import AVFoundation
import Foundation

@MainActor
final class PhoneInboxViewModel: ObservableObject {
    @Published private(set) var recordings: [InboxRecording] = []
    @Published private(set) var transcriptDrafts: [InboxRecording.ID: TranscriptDraft] = [:]
    @Published private(set) var processingTranscriptIDs: Set<InboxRecording.ID> = []
    @Published private(set) var audioEnhancedRecordingIDs: Set<InboxRecording.ID> = []
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
        recoverInterruptedTranscriptions()
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

        var transcriptionStartedAt: Date?

        do {
            try store.updateTranscriptionState(
                recordingID: recording.id,
                status: .transcribing,
                errorMessage: nil,
                attemptedAt: Date(),
                incrementsAttemptCount: true
            )
            reload(status: "Transcribing recording")

            transcriptionStartedAt = Date()
            let transcriptPipeline = try makeTranscriptPipeline()
            var temporarySegmentURLs: [URL] = []
            var temporaryUploadURLs: [URL] = []
            var didEnhanceAudio = false
            defer {
                temporarySegmentURLs.forEach { try? FileManager.default.removeItem(at: $0) }
                temporaryUploadURLs.forEach { try? FileManager.default.removeItem(at: $0) }
            }

            let draft: TranscriptDraft
            switch PhoneLongAudioProcessingStrategy.default.decision(
                durationSeconds: recording.durationSeconds,
                audioByteCount: recording.audioByteCount
            ) {
            case .singlePass:
                reload(status: "Enhancing audio")
                let uploadAudio = try prepareAudioForUpload(
                    audioFileURL: recording.fileURL,
                    recordingID: recording.id,
                    label: "single"
                )
                if let temporaryURL = uploadAudio.temporaryFileURL {
                    temporaryUploadURLs.append(temporaryURL)
                }
                didEnhanceAudio = didEnhanceAudio || uploadAudio.wasEnhanced
                reload(status: "Transcribing recording")
                draft = try await transcriptPipeline.makeDraft(
                    recordingID: recording.id,
                    audioFileURL: uploadAudio.fileURL,
                    hint: recording.originalFileName
                )
            case .segmented(let segmentDurationSeconds, let overlapSeconds):
                let plan = PhoneAudioSegmentPlan.make(
                    durationSeconds: recording.durationSeconds,
                    segmentDurationSeconds: segmentDurationSeconds,
                    overlapSeconds: overlapSeconds
                )
                reload(status: "Segmenting recording into \(plan.segments.count) parts")
                temporarySegmentURLs = try await AudioSegmentExporter().exportSegments(
                    audioFileURL: recording.fileURL,
                    recordingID: recording.id,
                    segments: plan.segments
                )
                reload(status: "Transcribing \(temporarySegmentURLs.count) segments")
                let uploadSegmentURLs = try temporarySegmentURLs.enumerated().map { index, segmentURL in
                    let uploadAudio = try prepareAudioForUpload(
                        audioFileURL: segmentURL,
                        recordingID: recording.id,
                        label: "segment-\(index)"
                    )
                    if let temporaryURL = uploadAudio.temporaryFileURL {
                        temporaryUploadURLs.append(temporaryURL)
                    }
                    didEnhanceAudio = didEnhanceAudio || uploadAudio.wasEnhanced
                    return uploadAudio.fileURL
                }
                draft = try await transcriptPipeline.makeDraftFromSegments(
                    recordingID: recording.id,
                    segmentFileURLs: uploadSegmentURLs,
                    hint: recording.originalFileName
                )
            }
            let transcriptionDuration = transcriptionStartedAt.map { Date().timeIntervalSince($0) }
            try draftStore.save(draft)
            try store.updateTranscriptionState(
                recordingID: recording.id,
                status: .draftReady,
                errorMessage: nil,
                attemptedAt: Date(),
                incrementsAttemptCount: false,
                durationSeconds: transcriptionDuration
            )
            transcriptDrafts[recording.id] = draft
            if didEnhanceAudio {
                audioEnhancedRecordingIDs.insert(recording.id)
            }
            reload(status: "Draft ready")
        } catch {
            let duration = transcriptionStartedAt.map { Date().timeIntervalSince($0) }
            try? store.updateTranscriptionState(
                recordingID: recording.id,
                status: .transcriptionFailed,
                errorMessage: error.localizedDescription,
                attemptedAt: Date(),
                incrementsAttemptCount: false,
                durationSeconds: duration
            )
            reload(status: "Draft failed: \(error.localizedDescription)")
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

    private func recoverInterruptedTranscriptions() {
        do {
            let recoveredCount = try store.markInterruptedTranscriptionsFailed(
                message: "Interrupted before finishing. Tap retry.",
                at: Date()
            )

            if recoveredCount > 0 {
                reload(status: "\(recoveredCount) interrupted draft\(recoveredCount == 1 ? "" : "s") need retry")
            }
        } catch {
            statusText = "Recovery check failed: \(error.localizedDescription)"
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

    private func prepareAudioForUpload(
        audioFileURL: URL,
        recordingID: InboxRecording.ID,
        label: String
    ) throws -> AudioUploadPreparation {
        guard providerSettings.selectedProvider == .openAICompatible else {
            return AudioUploadPreparation(fileURL: audioFileURL, temporaryFileURL: nil, wasEnhanced: false)
        }

        do {
            return try AudioUploadPreprocessor().prepare(
                audioFileURL: audioFileURL,
                recordingID: recordingID,
                label: label
            )
        } catch {
            statusText = "Audio enhancement skipped: \(error.localizedDescription)"
            return AudioUploadPreparation(fileURL: audioFileURL, temporaryFileURL: nil, wasEnhanced: false)
        }
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

private enum PhoneLongAudioProcessingDecision {
    case singlePass
    case segmented(segmentDurationSeconds: TimeInterval, overlapSeconds: TimeInterval)
}

private struct PhoneLongAudioProcessingStrategy {
    static let `default` = PhoneLongAudioProcessingStrategy(
        durationThresholdSeconds: 10 * 60,
        byteThreshold: 5 * 1_024 * 1_024,
        segmentDurationSeconds: 5 * 60,
        overlapSeconds: 15
    )

    let durationThresholdSeconds: TimeInterval
    let byteThreshold: Int64
    let segmentDurationSeconds: TimeInterval
    let overlapSeconds: TimeInterval

    func decision(durationSeconds: TimeInterval, audioByteCount: Int64?) -> PhoneLongAudioProcessingDecision {
        if durationSeconds > durationThresholdSeconds || (audioByteCount ?? 0) > byteThreshold {
            return .segmented(
                segmentDurationSeconds: segmentDurationSeconds,
                overlapSeconds: overlapSeconds
            )
        }

        return .singlePass
    }
}

private struct PhoneAudioSegment {
    let index: Int
    let startSeconds: TimeInterval
    let endSeconds: TimeInterval
}

private struct PhoneAudioSegmentPlan {
    let segments: [PhoneAudioSegment]

    static func make(
        durationSeconds: TimeInterval,
        segmentDurationSeconds: TimeInterval,
        overlapSeconds: TimeInterval
    ) -> PhoneAudioSegmentPlan {
        guard durationSeconds > 0, segmentDurationSeconds > 0 else {
            return PhoneAudioSegmentPlan(segments: [])
        }

        let safeOverlap = min(max(overlapSeconds, 0), max(segmentDurationSeconds - 1, 0))
        let step = segmentDurationSeconds - safeOverlap
        var segments: [PhoneAudioSegment] = []
        var index = 0
        var start: TimeInterval = 0

        while start < durationSeconds {
            let end = min(start + segmentDurationSeconds, durationSeconds)
            segments.append(PhoneAudioSegment(index: index, startSeconds: start, endSeconds: end))

            if end >= durationSeconds {
                break
            }

            index += 1
            start += step
        }

        return PhoneAudioSegmentPlan(segments: segments)
    }
}

private struct AudioSegmentExporter {
    func exportSegments(
        audioFileURL: URL,
        recordingID: UUID,
        segments: [PhoneAudioSegment]
    ) async throws -> [URL] {
        guard !segments.isEmpty else {
            throw AudioSegmentExporterError.emptyPlan
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WatchMemoAudioSegments", isDirectory: true)
            .appendingPathComponent(recordingID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var outputURLs: [URL] = []
        for segment in segments {
            let outputURL = directory.appendingPathComponent("segment-\(segment.index).m4a")
            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }

            try await exportSegment(
                audioFileURL: audioFileURL,
                segment: segment,
                outputURL: outputURL
            )
            outputURLs.append(outputURL)
        }

        return outputURLs
    }

    private func exportSegment(
        audioFileURL: URL,
        segment: PhoneAudioSegment,
        outputURL: URL
    ) async throws {
        let asset = AVURLAsset(url: audioFileURL)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioSegmentExporterError.exportSessionUnavailable
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .m4a
        exporter.timeRange = CMTimeRange(
            start: CMTime(seconds: segment.startSeconds, preferredTimescale: 600),
            end: CMTime(seconds: segment.endSeconds, preferredTimescale: 600)
        )

        try await withCheckedThrowingContinuation { continuation in
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    continuation.resume()
                case .failed:
                    continuation.resume(throwing: exporter.error ?? AudioSegmentExporterError.exportFailed)
                case .cancelled:
                    continuation.resume(throwing: AudioSegmentExporterError.exportCancelled)
                default:
                    continuation.resume(throwing: AudioSegmentExporterError.exportFailed)
                }
            }
        }
    }
}

private enum AudioSegmentExporterError: LocalizedError {
    case emptyPlan
    case exportSessionUnavailable
    case exportFailed
    case exportCancelled

    var errorDescription: String? {
        switch self {
        case .emptyPlan:
            return "Audio segmentation plan is empty"
        case .exportSessionUnavailable:
            return "Audio segment exporter is unavailable"
        case .exportFailed:
            return "Audio segment export failed"
        case .exportCancelled:
            return "Audio segment export was cancelled"
        }
    }
}

private struct AudioUploadPreparation {
    let fileURL: URL
    let temporaryFileURL: URL?
    let wasEnhanced: Bool
}

private struct AudioUploadPreprocessor {
    private let targetRMS: Float = pow(10, -26.0 / 20.0)
    private let silenceRMS: Float = pow(10, -58.0 / 20.0)
    private let peakHeadroom: Float = pow(10, -1.0 / 20.0)
    private let maxGain: Float = pow(10, 18.0 / 20.0)
    private let minimumUsefulGain: Float = pow(10, 3.0 / 20.0)

    func prepare(
        audioFileURL: URL,
        recordingID: UUID,
        label: String
    ) throws -> AudioUploadPreparation {
        let inputFile = try AVAudioFile(forReading: audioFileURL)
        let format = inputFile.processingFormat
        let frameCount = AVAudioFrameCount(inputFile.length)

        guard frameCount > 0,
              let inputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return AudioUploadPreparation(fileURL: audioFileURL, temporaryFileURL: nil, wasEnhanced: false)
        }

        try inputFile.read(into: inputBuffer)
        guard let channelData = inputBuffer.floatChannelData else {
            return AudioUploadPreparation(fileURL: audioFileURL, temporaryFileURL: nil, wasEnhanced: false)
        }

        let frameLength = Int(inputBuffer.frameLength)
        let channelCount = Int(format.channelCount)
        guard frameLength > 0, channelCount > 0 else {
            return AudioUploadPreparation(fileURL: audioFileURL, temporaryFileURL: nil, wasEnhanced: false)
        }

        var didEnhance = false
        let windowFrameCount = max(Int(format.sampleRate * 0.5), 1)
        var startFrame = 0

        while startFrame < frameLength {
            let endFrame = min(startFrame + windowFrameCount, frameLength)
            let gain = gainForWindow(
                channelData: channelData,
                channelCount: channelCount,
                startFrame: startFrame,
                endFrame: endFrame
            )

            if gain >= minimumUsefulGain {
                didEnhance = true
                apply(gain: gain, to: channelData, channelCount: channelCount, startFrame: startFrame, endFrame: endFrame)
            }

            startFrame = endFrame
        }

        guard didEnhance else {
            return AudioUploadPreparation(fileURL: audioFileURL, temporaryFileURL: nil, wasEnhanced: false)
        }

        let outputURL = try makeOutputURL(recordingID: recordingID, label: label)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64_000
        ]
        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputSettings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        try outputFile.write(from: inputBuffer)

        return AudioUploadPreparation(fileURL: outputURL, temporaryFileURL: outputURL, wasEnhanced: true)
    }

    private func gainForWindow(
        channelData: UnsafePointer<UnsafeMutablePointer<Float>>,
        channelCount: Int,
        startFrame: Int,
        endFrame: Int
    ) -> Float {
        var squareSum: Double = 0
        var peak: Float = 0
        var sampleCount = 0

        for channelIndex in 0..<channelCount {
            let samples = channelData[channelIndex]
            for frameIndex in startFrame..<endFrame {
                let value = samples[frameIndex]
                squareSum += Double(value * value)
                peak = max(peak, abs(value))
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else {
            return 1
        }

        let rms = Float(sqrt(squareSum / Double(sampleCount)))
        guard rms > silenceRMS, peak > 0 else {
            return 1
        }

        return min(targetRMS / rms, peakHeadroom / peak, maxGain)
    }

    private func apply(
        gain: Float,
        to channelData: UnsafePointer<UnsafeMutablePointer<Float>>,
        channelCount: Int,
        startFrame: Int,
        endFrame: Int
    ) {
        for channelIndex in 0..<channelCount {
            let samples = channelData[channelIndex]
            for frameIndex in startFrame..<endFrame {
                samples[frameIndex] = samples[frameIndex] * gain
            }
        }
    }

    private func makeOutputURL(recordingID: UUID, label: String) throws -> URL {
        let safeLabel = label.replacingOccurrences(of: #"[^A-Za-z0-9_-]"#, with: "-", options: .regularExpression)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WatchMemoEnhancedAudio", isDirectory: true)
            .appendingPathComponent(recordingID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let outputURL = directory.appendingPathComponent("\(safeLabel)-enhanced.m4a")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        return outputURL
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
