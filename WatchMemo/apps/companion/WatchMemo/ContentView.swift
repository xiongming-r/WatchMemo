import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var inbox: PhoneInboxViewModel
    @StateObject private var playback = AudioPlaybackController()
    @State private var isShowingProviderSettings = false
    @State private var isShowingObsidianSettings = false

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
                            isAudioEnhanced: inbox.audioEnhancedRecordingIDs.contains(recording.id),
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
                            },
                            onExportObsidianTapped: {
                                exportToObsidian(recording: recording)
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

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingObsidianSettings = true
                    } label: {
                        Image(systemName: "books.vertical")
                    }
                    .accessibilityLabel("Obsidian settings")
                }
            }
            .sheet(isPresented: $isShowingProviderSettings) {
                ProviderSettingsView(inbox: inbox)
            }
            .sheet(isPresented: $isShowingObsidianSettings) {
                ObsidianSettingsView(inbox: inbox)
            }
        }
    }

    private func exportToObsidian(recording: InboxRecording) {
        do {
            let url = try inbox.makeObsidianExportURL(for: recording)

            guard inbox.obsidianSettings.openAfterExport else {
                UIPasteboard.general.string = url.absoluteString
                inbox.markObsidianURICopied()
                return
            }

            UIApplication.shared.open(url) { opened in
                Task { @MainActor in
                    inbox.markObsidianExportResult(opened: opened)
                }
            }
        } catch let error as ObsidianExportError {
            if case .contentTooLarge = error,
               let markdown = inbox.transcriptDrafts[recording.id]?.markdownText {
                UIPasteboard.general.string = markdown
                inbox.markLongObsidianNoteCopied(error)
            } else {
                inbox.markObsidianExportFailed(error)
            }
        } catch {
            inbox.markObsidianExportFailed(error)
        }
    }
}

private struct RecordingRow: View {
    let recording: InboxRecording
    let draft: TranscriptDraft?
    let isPlaying: Bool
    let isProcessingTranscript: Bool
    let isAudioEnhanced: Bool
    let onPlayTapped: () -> Void
    let onTranscriptTapped: () -> Void
    let onCopyMarkdownTapped: () -> Void
    let onExportObsidianTapped: () -> Void

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

                if !diagnosticText.isEmpty {
                    Text(diagnosticText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(transcriptionStatusText)
                    .font(.caption2)
                    .foregroundStyle(transcriptionStatusColor)
                    .lineLimit(2)

                if let draft {
                    NotePreview(draft: draft)
                        .padding(.top, 2)

                    Button(action: onCopyMarkdownTapped) {
                        Label("Copy Markdown", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Copy Markdown")

                    Button(action: onExportObsidianTapped) {
                        Label("Export Obsidian", systemImage: "books.vertical")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Export Obsidian")
                }
            }

            Spacer(minLength: 8)

            if isProcessingTranscript {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 28, height: 28)
            } else {
                Button(action: onTranscriptTapped) {
                    Image(systemName: transcriptButtonIcon)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(transcriptButtonLabel)
            }
        }
        .padding(.vertical, 4)
    }

    private var transcriptionStatusText: String {
        switch recording.status {
        case .readyForTranscription:
            return "Draft not created"
        case .transcribing:
            return isProcessingTranscript ? "Draft in progress" : "Draft interrupted. Tap retry."
        case .draftReady:
            return "Draft ready"
        case .transcriptionFailed:
            let attempts = recording.transcriptionAttemptCount
            let attemptText = attempts > 0 ? " after \(attempts) attempt\(attempts == 1 ? "" : "s")" : ""
            if let message = recording.transcriptionErrorMessage, !message.isEmpty {
                return "Draft failed\(attemptText): \(message)"
            }
            return "Draft failed\(attemptText)"
        case .transcribingLater:
            return "Draft queued"
        }
    }

    private var transcriptionStatusColor: Color {
        switch recording.status {
        case .draftReady:
            return .green
        case .transcriptionFailed:
            return .red
        case .transcribing:
            return isProcessingTranscript ? .secondary : .orange
        case .readyForTranscription, .transcribingLater:
            return .secondary
        }
    }

    private var transcriptButtonIcon: String {
        switch recording.status {
        case .transcriptionFailed, .transcribing:
            return "arrow.triangle.2.circlepath"
        case .draftReady:
            return "arrow.triangle.2.circlepath"
        case .readyForTranscription, .transcribingLater:
            return draft == nil ? "sparkles" : "arrow.triangle.2.circlepath"
        }
    }

    private var transcriptButtonLabel: String {
        switch recording.status {
        case .transcriptionFailed, .transcribing:
            return "Retry draft"
        case .draftReady:
            return "Refresh draft"
        case .readyForTranscription, .transcribingLater:
            return draft == nil ? "Create draft" : "Refresh draft"
        }
    }

    private var diagnosticText: String {
        var parts: [String] = []

        if let audioByteCount = recording.audioByteCount {
            parts.append(format(bytes: audioByteCount))
        }

        if let duration = recording.lastTranscriptionDurationSeconds {
            parts.append("AI \(formatPrecise(duration: duration))")
        }

        if isAudioEnhanced {
            parts.append("Enhanced audio")
        }

        if let metrics = draft?.qualityMetrics {
            parts.append(format(metrics: metrics))
        }

        return parts.joined(separator: " | ")
    }

    private func format(duration: TimeInterval) -> String {
        let seconds = max(Int(duration.rounded()), 0)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func formatPrecise(duration: TimeInterval) -> String {
        if duration < 10 {
            return String(format: "%.1fs", max(duration, 0))
        }

        return String(format: "%.0fs", max(duration, 0))
    }

    private func format(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func format(metrics: TranscriptQualityMetrics) -> String {
        var parts = [
            "Text \(metrics.rawCharacterCount)->\(metrics.cleanedCharacterCount)"
        ]

        if let ratio = metrics.compressionRatio {
            parts.append("\(Int((ratio * 100).rounded()))%")
        }

        if metrics.usedSegmentedProcessing || metrics.segmentCount > 1 {
            parts.append("Segments \(metrics.segmentCount)")
        }

        if metrics.hasSpeakerLabels {
            parts.append("Speakers \(metrics.estimatedSpeakerCount)")
        }

        return parts.joined(separator: " ")
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
