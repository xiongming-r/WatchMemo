import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var inbox: PhoneInboxViewModel
    @StateObject private var playback = AudioPlaybackController()
    @State private var isShowingProviderSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Text(inbox.statusText)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        Spacer(minLength: 8)

                        Button {
                            UIPasteboard.general.string = inbox.statusText
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Copy status")
                    }
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
                            },
                            onCopyMarkdownTapped: {
                                if let markdown = inbox.transcriptDrafts[recording.id]?.markdownText {
                                    UIPasteboard.general.string = markdown
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
    let onCopyMarkdownTapped: () -> Void

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
                    NotePreview(draft: draft)
                        .padding(.top, 2)

                    Button(action: onCopyMarkdownTapped) {
                        Label("Copy Markdown", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Copy Markdown")
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

private struct NotePreview: View {
    let draft: TranscriptDraft

    var body: some View {
        if let note = draft.structuredNote {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(note.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !note.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(note.actionItems, id: \.self) { item in
                            Label(item, systemImage: "checklist.unchecked")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        } else {
            Text(draft.cleanedText)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension TranscriptDraft {
    var markdownText: String {
        structuredNote?.markdown ?? cleanedText
    }
}
