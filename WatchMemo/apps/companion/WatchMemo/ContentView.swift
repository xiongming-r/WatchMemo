import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var inbox: PhoneInboxViewModel
    @StateObject private var playback = AudioPlaybackController()
    @State private var isShowingProviderSettings = false

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
                            draft: inbox.transcriptDrafts[recording.id],
                            isPlaying: playback.playingID == recording.id,
                            isProcessingTranscript: inbox.processingTranscriptIDs.contains(recording.id),
                            onPlayTapped: {
                                playback.toggle(recording: recording)
                            },
                            onTranscriptTapped: {
                                Task {
                                    await inbox.processTranscript(for: recording)
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("WatchMemo")
            .toolbar {
#if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        inbox.importSampleRecording()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Import sample")
                }
#endif

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingProviderSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Provider settings")
                }
            }
            .sheet(isPresented: $isShowingProviderSettings) {
                ProviderSettingsView(inbox: inbox)
            }
        }
    }
}

private struct RecordingRow: View {
    let recording: InboxRecording
    let draft: TranscriptDraft?
    let isPlaying: Bool
    let isProcessingTranscript: Bool
    let onPlayTapped: () -> Void
    let onTranscriptTapped: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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

                if let draft {
                    Text(draft.cleanedText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            if isProcessingTranscript {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 28, height: 28)
            } else {
                Button(action: onTranscriptTapped) {
                    Image(systemName: draft == nil ? "sparkles" : "arrow.triangle.2.circlepath")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(draft == nil ? "Create draft" : "Refresh draft")
            }
        }
        .padding(.vertical, 4)
    }

    private func format(duration: TimeInterval) -> String {
        let seconds = max(Int(duration.rounded()), 0)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
