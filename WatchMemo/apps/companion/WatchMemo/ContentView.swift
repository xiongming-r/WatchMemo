import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var inbox: PhoneInboxViewModel
    @StateObject private var playback = AudioPlaybackController()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(inbox.statusText)
                        .foregroundStyle(.secondary)
                }

                if inbox.recordings.isEmpty {
                    ContentUnavailableView(
                        "Inbox is empty",
                        systemImage: "waveform"
                    )
                } else {
                    ForEach(inbox.recordings) { recording in
                        RecordingRow(
                            recording: recording,
                            isPlaying: playback.playingID == recording.id,
                            onPlayTapped: {
                                playback.toggle(recording: recording)
                            }
                        )
                    }
                }
            }
            .navigationTitle("WatchMemo")
#if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        inbox.importSampleRecording()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Import sample")
                }
            }
#endif
        }
    }
}

private struct RecordingRow: View {
    let recording: InboxRecording
    let isPlaying: Bool
    let onPlayTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlayTapped) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isPlaying ? "Stop" : "Play")

            VStack(alignment: .leading, spacing: 5) {
                Text(recording.originalFileName)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(recording.createdAt, style: .time)
                    Text(format(duration: recording.durationSeconds))
                    Text(recording.source == .watchConnectivity ? "Watch" : "Sim")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func format(duration: TimeInterval) -> String {
        let seconds = max(Int(duration.rounded()), 0)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
