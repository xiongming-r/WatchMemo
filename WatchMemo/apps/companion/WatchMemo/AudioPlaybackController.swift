import AVFoundation
import Foundation

@MainActor
final class AudioPlaybackController: ObservableObject {
    @Published private(set) var playingID: InboxRecording.ID?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var progressTask: Task<Void, Never>?

    func toggle(recording: InboxRecording) {
        if playingID == recording.id {
            stop()
            return
        }

        do {
            stop()

            let player = try AVAudioPlayer(contentsOf: recording.fileURL)
            player.prepareToPlay()
            player.play()

            self.player = player
            playingID = recording.id
            currentTime = 0
            duration = max(player.duration, 0)

            progressTask = Task { @MainActor in
                while !Task.isCancelled, playingID == recording.id {
                    currentTime = player.currentTime

                    if !player.isPlaying {
                        stop()
                        break
                    }

                    try? await Task.sleep(for: .milliseconds(200))
                }
            }
        } catch {
            stop()
        }
    }

    func progress(for recordingID: InboxRecording.ID) -> (currentTime: TimeInterval, duration: TimeInterval) {
        guard playingID == recordingID else {
            return (0, 0)
        }

        return (currentTime, duration)
    }

    func stop() {
        progressTask?.cancel()
        progressTask = nil
        player?.stop()
        player = nil
        playingID = nil
        currentTime = 0
    }
}
