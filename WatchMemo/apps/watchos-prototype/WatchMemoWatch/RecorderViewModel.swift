import AVFoundation
import Foundation

@MainActor
final class RecorderViewModel: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds = 0
    @Published var message: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var didRunAutotest = false

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
        message = "Autotest recording saved"
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

            let url = makeRecordingURL()
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
            isRecording = true
            elapsedSeconds = 0
            message = "Saving locally"
            startTimer()
        } catch {
            message = "Recording failed: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        stopTimer()
        message = "Recording saved"

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            message = "Saved, but audio session cleanup failed"
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

    private func makeRecordingURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let fileName = "watchmemo-\(formatter.string(from: Date())).m4a"
            .replacingOccurrences(of: ":", with: "-")
        return directory.appendingPathComponent(fileName)
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
