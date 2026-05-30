import AVFoundation
import Foundation

@MainActor
final class AudioPlaybackController: ObservableObject {
    @Published private(set) var playingID: InboxRecording.ID?

    private var player: AVAudioPlayer?
    private var finishTask: Task<Void, Never>?

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

            let duration = max(player.duration, 0.1)
            finishTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration))
                if playingID == recording.id {
                    stop()
                }
            }
        } catch {
            stop()
        }
    }

    func stop() {
        finishTask?.cancel()
        finishTask = nil
        player?.stop()
        player = nil
        playingID = nil
    }
}
