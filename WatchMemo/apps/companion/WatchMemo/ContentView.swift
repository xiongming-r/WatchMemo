import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var inbox: PhoneInboxViewModel
    @StateObject private var playback = AudioPlaybackController()
    @State private var selectedFilter: RecordingFilter = .all
    @State private var expandedRecordingIDs: Set<InboxRecording.ID> = []
    @State private var isShowingProviderSettings = false
    @State private var isShowingObsidianSettings = false
    @State private var placeholderNotice: String?

    private var filteredRecordings: [InboxRecording] {
        inbox.recordings.filter { selectedFilter.includes($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.wmBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    AppHeader(
                        onProviderSettingsTapped: { isShowingProviderSettings = true },
                        onObsidianSettingsTapped: { isShowingObsidianSettings = true },
                        onAccountTapped: { showPlaceholder("Account is not implemented yet") },
                        onImportSampleTapped: {
#if DEBUG
                            inbox.importSampleRecording()
#else
                            showPlaceholder("Debug import is unavailable in this build")
#endif
                        }
                    )

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            StatusStrip(
                                text: placeholderNotice ?? inbox.statusText,
                                onCopyTapped: {
                                    UIPasteboard.general.string = placeholderNotice ?? inbox.statusText
                                }
                            )

                            RecordingFilterControl(selection: $selectedFilter)

                            if inbox.recordings.isEmpty {
                                EmptyInboxView()
                                    .padding(.top, 64)
                            } else if filteredRecordings.isEmpty {
                                EmptyFilterView(filter: selectedFilter)
                                    .padding(.top, 64)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(filteredRecordings) { recording in
                                        RecordingCard(
                                            recording: recording,
                                            draft: inbox.transcriptDrafts[recording.id],
                                            isPlaying: playback.playingID == recording.id,
                                            isProcessingTranscript: inbox.processingTranscriptIDs.contains(recording.id),
                                            isAudioEnhanced: inbox.audioEnhancedRecordingIDs.contains(recording.id),
                                            isExpanded: expandedRecordingIDs.contains(recording.id),
                                            onToggleExpanded: {
                                                toggleExpanded(recording.id)
                                            },
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
                                                    showPlaceholder("Markdown copied")
                                                }
                                            },
                                            onExportObsidianTapped: {
                                                exportToObsidian(recording: recording)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 112)
                    }
                }

                FloatingMemoButton {
                    showPlaceholder("iPhone recording is not implemented yet. Use Apple Watch recording for now.")
                }
                .padding(.trailing, 24)
                .padding(.bottom, 82)

                BottomNavBar(
                    onInboxTapped: { selectedFilter = .all },
                    onArchiveTapped: { showPlaceholder("Archive is not implemented yet") },
                    onSettingsTapped: { isShowingProviderSettings = true }
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingProviderSettings) {
                ProviderSettingsView(inbox: inbox)
            }
            .sheet(isPresented: $isShowingObsidianSettings) {
                ObsidianSettingsView(inbox: inbox)
            }
        }
    }

    private func toggleExpanded(_ id: InboxRecording.ID) {
        if expandedRecordingIDs.contains(id) {
            expandedRecordingIDs.remove(id)
        } else {
            expandedRecordingIDs.insert(id)
        }
    }

    private func showPlaceholder(_ message: String) {
        placeholderNotice = message
    }

    private func exportToObsidian(recording: InboxRecording) {
        do {
            let url = try inbox.makeObsidianExportURL(for: recording)

            guard inbox.obsidianSettings.openAfterExport else {
                UIPasteboard.general.string = url.absoluteString
                inbox.markObsidianURICopied()
                placeholderNotice = nil
                return
            }

            UIApplication.shared.open(url) { opened in
                Task { @MainActor in
                    inbox.markObsidianExportResult(opened: opened)
                    placeholderNotice = nil
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
            placeholderNotice = nil
        } catch {
            inbox.markObsidianExportFailed(error)
            placeholderNotice = nil
        }
    }
}

private enum RecordingFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case done = "Done"
    case failed = "Failed"

    var id: String { rawValue }

    func includes(_ recording: InboxRecording) -> Bool {
        switch self {
        case .all:
            return true
        case .pending:
            return recording.status == .readyForTranscription
                || recording.status == .transcribing
                || recording.status == .transcribingLater
        case .done:
            return recording.status == .draftReady
        case .failed:
            return recording.status == .transcriptionFailed
        }
    }
}

private struct AppHeader: View {
    let onProviderSettingsTapped: () -> Void
    let onObsidianSettingsTapped: () -> Void
    let onAccountTapped: () -> Void
    let onImportSampleTapped: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("WatchMemo")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.wmPrimary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Spacer()

#if DEBUG
            HeaderIconButton(systemName: "square.and.arrow.down", action: onImportSampleTapped, label: "Import sample")
#endif
            HeaderIconButton(systemName: "books.vertical", action: onObsidianSettingsTapped, label: "Obsidian settings")
            HeaderIconButton(systemName: "gearshape", action: onProviderSettingsTapped, label: "Provider settings")
            HeaderIconButton(systemName: "person.circle", action: onAccountTapped, label: "Account")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
    }
}

private struct HeaderIconButton: View {
    let systemName: String
    let action: () -> Void
    let label: String

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.wmSecondaryText)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct StatusStrip: View {
    let text: String
    let onCopyTapped: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.wmCyan)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.wmSecondaryText)
                .textSelection(.enabled)
                .lineLimit(3)

            Spacer(minLength: 8)

            Button(action: onCopyTapped) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.wmSecondaryText)
                    .frame(width: 30, height: 30)
                    .background(Color.wmElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy status")
        }
        .padding(14)
        .background(Color.wmCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RecordingFilterControl: View {
    @Binding var selection: RecordingFilter

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RecordingFilter.allCases) { filter in
                Button {
                    selection = filter
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(selection == filter ? Color.wmPrimary : Color.wmSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == filter ? Color.wmElevated : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.wmCard.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct RecordingCard: View {
    let recording: InboxRecording
    let draft: TranscriptDraft?
    let isPlaying: Bool
    let isProcessingTranscript: Bool
    let isAudioEnhanced: Bool
    let isExpanded: Bool
    let onToggleExpanded: () -> Void
    let onPlayTapped: () -> Void
    let onTranscriptTapped: () -> Void
    let onCopyMarkdownTapped: () -> Void
    let onExportObsidianTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onToggleExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    cardHeader
                    metadataChips
                    statusArea

                    if isExpanded, let draft {
                        NotePreview(draft: draft)
                            .padding(.top, 2)
                    }
                }
            }
            .buttonStyle(.plain)

            if draft != nil || recording.status == .transcriptionFailed || recording.status == .readyForTranscription {
                Divider()
                    .overlay(Color.wmDivider)

                actionBar
            }
        }
        .padding(16)
        .background(Color.wmCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderColor, lineWidth: recording.status == .transcriptionFailed ? 1 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(recording.status == .transcriptionFailed ? Color.wmSecondaryText.opacity(0.72) : Color.wmText)
                    .lineLimit(2)

                Text(timestampText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.wmSecondaryText)
                    .textCase(.uppercase)
            }

            Spacer()

            Circle()
                .fill(statusDotColor)
                .frame(width: 9, height: 9)
                .shadow(color: statusDotColor.opacity(0.45), radius: 6)
                .padding(.top, 6)
        }
    }

    private var metadataChips: some View {
        HStack(spacing: 10) {
            InfoChip(systemName: "clock", text: format(duration: recording.durationSeconds))
            InfoChip(systemName: "record.circle", text: recording.audioByteCount.map(format(bytes:)) ?? "Audio")
            InfoChip(systemName: sourceIcon, text: sourceText)
        }
    }

    @ViewBuilder
    private var statusArea: some View {
        if isProcessingTranscript {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Processing...", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.wmCyan)

                    Spacer()

                    Text("AI")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.wmCyan)
                }

                ProgressView()
                    .tint(Color.wmCyan)
            }
        } else {
            HStack(spacing: 10) {
                Label(statusText, systemImage: statusIcon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(statusColor)

                Spacer()

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.wmSecondaryText)
                    .opacity(draft == nil ? 0.35 : 1)
            }

            if !diagnosticText.isEmpty {
                Text(diagnosticText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.wmSecondaryText)
                    .lineLimit(2)
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            CardActionButton(
                systemName: isPlaying ? "stop.fill" : "play.fill",
                title: isPlaying ? "Stop" : "Play",
                prominent: false,
                action: onPlayTapped
            )

            CardActionButton(
                systemName: transcriptButtonIcon,
                title: transcriptButtonTitle,
                prominent: recording.status != .draftReady,
                action: onTranscriptTapped
            )
            .disabled(isProcessingTranscript)
            .opacity(isProcessingTranscript ? 0.5 : 1)

            if draft != nil {
                CardActionButton(
                    systemName: "doc.on.doc",
                    title: "Copy",
                    prominent: false,
                    action: onCopyMarkdownTapped
                )

                CardActionButton(
                    systemName: "books.vertical",
                    title: "Obsidian",
                    prominent: true,
                    action: onExportObsidianTapped
                )
            }
        }
    }

    private var title: String {
        draft?.structuredNote?.title ?? recording.originalFileName
    }

    private var timestampText: String {
        if Date().timeIntervalSince(recording.createdAt) < 90 {
            return "Just now"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: recording.createdAt)
    }

    private var sourceIcon: String {
        recording.source == .watchConnectivity ? "applewatch" : "square.and.arrow.down"
    }

    private var sourceText: String {
        recording.source == .watchConnectivity ? "Watch" : "Sim"
    }

    private var statusDotColor: Color {
        switch recording.status {
        case .draftReady:
            return Color.wmGreen
        case .transcriptionFailed:
            return Color.wmWarning
        case .transcribing:
            return Color.wmCyan
        case .readyForTranscription, .transcribingLater:
            return Color.wmSecondaryText
        }
    }

    private var statusIcon: String {
        switch recording.status {
        case .draftReady:
            return "checkmark.circle"
        case .transcriptionFailed:
            return "exclamationmark.circle"
        case .transcribing:
            return "arrow.triangle.2.circlepath"
        case .readyForTranscription:
            return "sparkles"
        case .transcribingLater:
            return "clock.arrow.circlepath"
        }
    }

    private var statusText: String {
        switch recording.status {
        case .readyForTranscription:
            return "Ready for AI"
        case .transcribing:
            return isProcessingTranscript ? "Processing..." : "Interrupted. Retry"
        case .draftReady:
            return "Processed"
        case .transcriptionFailed:
            if let message = recording.transcriptionErrorMessage, !message.isEmpty {
                return "Transcription failed: \(message)"
            }
            return "Transcription failed"
        case .transcribingLater:
            return "Queued"
        }
    }

    private var statusColor: Color {
        switch recording.status {
        case .draftReady:
            return Color.wmGreen
        case .transcriptionFailed:
            return Color.wmWarning
        case .transcribing:
            return Color.wmCyan
        case .readyForTranscription, .transcribingLater:
            return Color.wmSecondaryText
        }
    }

    private var borderColor: Color {
        recording.status == .transcriptionFailed ? Color.wmRed.opacity(0.5) : Color.clear
    }

    private var transcriptButtonIcon: String {
        switch recording.status {
        case .transcriptionFailed, .transcribing, .draftReady:
            return "arrow.triangle.2.circlepath"
        case .readyForTranscription, .transcribingLater:
            return draft == nil ? "sparkles" : "arrow.triangle.2.circlepath"
        }
    }

    private var transcriptButtonTitle: String {
        switch recording.status {
        case .transcriptionFailed, .transcribing:
            return "Retry"
        case .draftReady:
            return "Refresh"
        case .readyForTranscription, .transcribingLater:
            return draft == nil ? "AI" : "Refresh"
        }
    }

    private var diagnosticText: String {
        var parts: [String] = []

        if let duration = recording.lastTranscriptionDurationSeconds {
            parts.append("AI \(formatPrecise(duration: duration))")
        }

        if isAudioEnhanced {
            parts.append("Enhanced audio")
        }

        if let metrics = draft?.qualityMetrics {
            parts.append(format(metrics: metrics))
        }

        return parts.joined(separator: " • ")
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

private struct InfoChip: View {
    let systemName: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))

            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(Color.wmSecondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.wmElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct CardActionButton: View {
    let systemName: String
    let title: String
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(prominent ? Color.wmOnCyan : Color.wmText)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(prominent ? Color.wmCyan : Color.wmElevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct NotePreview: View {
    let draft: TranscriptDraft

    var body: some View {
        if let note = draft.structuredNote {
            VStack(alignment: .leading, spacing: 14) {
                NoteSection(
                    title: "Summary",
                    systemName: "doc.text",
                    accent: Color.wmCyan,
                    content: note.summary
                )

                if !note.body.isEmpty {
                    NoteSection(
                        title: "Body",
                        systemName: "text.alignleft",
                        accent: Color.wmSecondaryText,
                        content: note.body,
                        lineLimit: 8
                    )
                }

                if !note.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Action Items", systemImage: "checklist")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.wmWarning)
                            .textCase(.uppercase)

                        ForEach(note.actionItems, id: \.self) { item in
                            Label(item, systemImage: "square")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(Color.wmText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(14)
                    .background(Color.wmElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !note.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.wmCyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.wmElevated)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        } else {
            Text(draft.cleanedText)
                .font(.system(size: 15))
                .foregroundStyle(Color.wmText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct NoteSection: View {
    let title: String
    let systemName: String
    let accent: Color
    let content: String
    var lineLimit: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemName)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .textCase(.uppercase)

            Text(content)
                .font(.system(size: 15))
                .foregroundStyle(Color.wmText)
                .lineLimit(lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.wmElevated.opacity(0.7))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accent)
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.wmCyan)

            Text("Inbox is empty")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.wmText)

            Text("Record from Apple Watch and new memos will appear here.")
                .font(.system(size: 15))
                .foregroundStyle(Color.wmSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EmptyFilterView: View {
    let filter: RecordingFilter

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 38))
                .foregroundStyle(Color.wmSecondaryText)

            Text("No \(filter.rawValue.lowercased()) recordings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.wmText)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FloatingMemoButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "mic.fill")
                .font(.system(size: 29, weight: .semibold))
                .foregroundStyle(Color.wmOnCyan)
                .frame(width: 70, height: 70)
                .background(Color.wmPrimary)
                .clipShape(Circle())
                .shadow(color: Color.wmPrimary.opacity(0.28), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Record on iPhone coming soon")
    }
}

private struct BottomNavBar: View {
    let onInboxTapped: () -> Void
    let onArchiveTapped: () -> Void
    let onSettingsTapped: () -> Void

    var body: some View {
        HStack {
            BottomNavItem(systemName: "tray.full", title: "Inbox", isSelected: true, action: onInboxTapped)
            BottomNavItem(systemName: "archivebox", title: "Archive", isSelected: false, action: onArchiveTapped)
            BottomNavItem(systemName: "gearshape", title: "Settings", isSelected: false, action: onSettingsTapped)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.wmDivider)
                .frame(height: 1)
        }
    }
}

private struct BottomNavItem: View {
    let systemName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.wmPrimary : Color.wmSecondaryText)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

private extension TranscriptDraft {
    var markdownText: String {
        structuredNote?.markdown ?? cleanedText
    }
}

private extension Color {
    static let wmBackground = Color(red: 0.05, green: 0.05, blue: 0.06)
    static let wmCard = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let wmElevated = Color(red: 0.18, green: 0.18, blue: 0.19)
    static let wmDivider = Color(red: 0.24, green: 0.28, blue: 0.30)
    static let wmText = Color(red: 0.89, green: 0.89, blue: 0.90)
    static let wmSecondaryText = Color(red: 0.72, green: 0.77, blue: 0.80)
    static let wmPrimary = Color(red: 0.73, green: 0.91, blue: 1.00)
    static let wmCyan = Color(red: 0.39, green: 0.82, blue: 1.00)
    static let wmOnCyan = Color(red: 0.00, green: 0.16, blue: 0.20)
    static let wmGreen = Color(red: 0.41, green: 1.00, blue: 0.45)
    static let wmWarning = Color(red: 1.00, green: 0.71, blue: 0.67)
    static let wmRed = Color(red: 1.00, green: 0.27, blue: 0.23)
}
