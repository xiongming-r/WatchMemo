import AVFoundation
import Foundation

@MainActor
final class RecorderViewModel: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds = 0
    @Published var message: String?

    private let store: LocalRecordingStore
    private let deliveryQueue: DeliveryQueue
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingStartedAt: Date?
    private var didRunAutotest = false

    override init() {
        let store = LocalRecordingStore()
        self.store = store
        self.deliveryQueue = DeliveryQueue(store: store, transport: IPhoneRelayTransport.shared)
        super.init()
    }

    var statusTitle: String {
        isRecording ? "Recording" : "Ready"
    }

    var elapsedText: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func prepare() async {
        let granted = await requestMicrophoneAccess()
        message = granted ? "Tap to record" : "Microphone permission needed"
        await deliveryQueue.retryPending()
    }

    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }

    func runAutotestIfRequested() async {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["WATCHMEMO_AUTOTEST_RECORDING"] == "1",
              !didRunAutotest else {
            return
        }

        didRunAutotest = true
        await startRecording()

        guard isRecording else {
            return
        }

        try? await Task.sleep(for: .seconds(3))
        stopRecording()
        #endif
    }

    private func startRecording() async {
        guard await requestMicrophoneAccess() else {
            message = "Enable microphone access in Settings"
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let startedAt = Date()
            let url = try await store.makeRecordingURL(createdAt: startedAt)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]

            let audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            audioRecorder.record()

            recorder = audioRecorder
            recordingStartedAt = startedAt
            isRecording = true
            elapsedSeconds = 0
            message = "Saving locally"
            startTimer()
        } catch {
            message = "Recording failed: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        guard let recorder else {
            return
        }

        let fileURL = recorder.url
        let startedAt = recordingStartedAt ?? Date()
        let duration = max(recorder.currentTime, Date().timeIntervalSince(startedAt))

        recorder.stop()
        self.recorder = nil
        recordingStartedAt = nil
        isRecording = false
        stopTimer()
        message = "Queueing locally"

        Task {
            await enqueueStoppedRecording(fileURL: fileURL, startedAt: startedAt, duration: duration)
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            message = "Saved, but audio session cleanup failed"
        }
    }

    private func enqueueStoppedRecording(fileURL: URL, startedAt: Date, duration: TimeInterval) async {
        do {
            _ = try await deliveryQueue.enqueue(
                fileURL: fileURL,
                createdAt: startedAt,
                durationSeconds: duration
            )
            message = "Queued locally"
        } catch {
            message = "Saved, queue failed: \(error.localizedDescription)"
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func requestMicrophoneAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

extension RecorderViewModel: AVAudioRecorderDelegate {
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.message = error?.localizedDescription ?? "Recording encode error"
            self.isRecording = false
            self.stopTimer()
        }
    }
}
