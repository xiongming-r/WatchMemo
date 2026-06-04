import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var inbox: PhoneInboxViewModel
    @EnvironmentObject private var appSettings: AppSettingsStore
    @StateObject private var playback = AudioPlaybackController()
    @State private var selectedMailbox: MailboxTab = .inbox
    @State private var selectedFilter: RecordingFilter = .all
    @State private var selectedRecording: SelectedRecording?
    @State private var isShowingSettings = false
    @State private var placeholderNotice: String?

    private var filteredRecordings: [InboxRecording] {
        inbox.recordings
            .filter { selectedMailbox.includes($0) }
            .filter { selectedFilter.includes($0) }
    }

    private var visibleMailboxRecordings: [InboxRecording] {
        inbox.recordings.filter { selectedMailbox.includes($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.wmBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    AppHeader(
                        onSettingsTapped: { isShowingSettings = true },
                        onAccountTapped: { showPlaceholder(t("Account is not implemented yet", "账号功能暂未开发")) },
                        onImportSampleTapped: {
#if DEBUG
                            inbox.importSampleRecording()
#else
                            showPlaceholder(t("Debug import is unavailable in this build", "当前构建不可用调试导入"))
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

                            if visibleMailboxRecordings.isEmpty {
                                EmptyMailboxView(mailbox: selectedMailbox)
                                    .padding(.top, 64)
                            } else if filteredRecordings.isEmpty {
                                EmptyFilterView(filter: selectedFilter, mailbox: selectedMailbox)
                                    .padding(.top, 64)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(filteredRecordings) { recording in
                                        RecordingCard(
                                            recording: recording,
                                            draft: inbox.transcriptDrafts[recording.id],
                                            obsidianSettings: inbox.obsidianSettings,
                                            isPlaying: playback.playingID == recording.id,
                                            isProcessingTranscript: inbox.processingTranscriptIDs.contains(recording.id),
                                            isAudioEnhanced: inbox.audioEnhancedRecordingIDs.contains(recording.id),
                                            onOpenTapped: {
                                                selectedRecording = SelectedRecording(id: recording.id)
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
                                                    showPlaceholder(t("Markdown copied", "Markdown 已复制"))
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
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 96)
                    }
                }

                if selectedMailbox == .inbox {
                    FloatingMemoButton {
                        showPlaceholder(t("iPhone recording is not implemented yet. Use Apple Watch recording for now.", "iPhone 录音暂未开发，请先使用 Apple Watch 录音。"))
                    }
                    .padding(.trailing, 22)
                    .padding(.bottom, 76)
                }

                BottomNavBar(
                    selectedMailbox: selectedMailbox,
                    onInboxTapped: {
                        selectedMailbox = .inbox
                        selectedFilter = .all
                    },
                    onArchiveTapped: {
                        selectedMailbox = .archive
                        selectedFilter = .all
                    },
                    onSettingsTapped: { isShowingSettings = true }
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedRecording) { selection in
                if let recording = inbox.recordings.first(where: { $0.id == selection.id }) {
                    MemoDetailScreen(
                        recording: recording,
                        draft: inbox.transcriptDrafts[recording.id],
                        obsidianSettings: inbox.obsidianSettings,
                        isPlaying: playback.playingID == recording.id,
                        playbackProgress: playback.progress(for: recording.id),
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
                                showPlaceholder(t("Markdown copied", "Markdown 已复制"))
                            }
                        },
                        onExportObsidianTapped: {
                            exportToObsidian(recording: recording)
                        },
                        onArchiveStateTapped: {
                            toggleArchiveState(recording: recording)
                        }
                    )
                    .environmentObject(appSettings)
                    .toolbar(.visible, for: .navigationBar)
                } else {
                    MissingRecordingView()
                        .environmentObject(appSettings)
                        .toolbar(.visible, for: .navigationBar)
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                AppSettingsView(inbox: inbox)
                    .environmentObject(appSettings)
            }
        }
    }

    private func showPlaceholder(_ message: String) {
        placeholderNotice = message
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
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

    private func toggleArchiveState(recording: InboxRecording) {
        if recording.isArchived {
            inbox.restore(recording: recording)
        } else {
            inbox.archive(recording: recording)
        }
        placeholderNotice = nil
    }
}

private struct SelectedRecording: Identifiable, Hashable {
    let id: InboxRecording.ID
}

private enum MailboxTab: String, Identifiable {
    case inbox
    case archive

    var id: String { rawValue }

    func includes(_ recording: InboxRecording) -> Bool {
        switch self {
        case .inbox:
            return !recording.isArchived
        case .archive:
            return recording.isArchived
        }
    }

    @MainActor
    func emptyTitle(using settings: AppSettingsStore) -> String {
        switch self {
        case .inbox:
            return settings.text("Inbox is empty", "收件箱为空")
        case .archive:
            return settings.text("Archive is empty", "归档为空")
        }
    }

    @MainActor
    func emptyMessage(using settings: AppSettingsStore) -> String {
        switch self {
        case .inbox:
            return settings.text(
                "Record from Apple Watch and new memos will appear here.",
                "从 Apple Watch 录音后，新记录会出现在这里。"
            )
        case .archive:
            return settings.text(
                "Processed memos you archive will stay available here.",
                "你归档后的记录会保留在这里，仍可播放、复制和导出。"
            )
        }
    }

    var emptyIconName: String {
        switch self {
        case .inbox:
            return "waveform.circle"
        case .archive:
            return "archivebox"
        }
    }
}

private enum RecordingFilter: CaseIterable, Identifiable {
    case all
    case pending
    case done
    case failed

    var id: String {
        switch self {
        case .all:
            return "all"
        case .pending:
            return "pending"
        case .done:
            return "done"
        case .failed:
            return "failed"
        }
    }

    @MainActor
    func title(using settings: AppSettingsStore) -> String {
        switch self {
        case .all:
            return settings.text("All", "全部")
        case .pending:
            return settings.text("Pending", "待处理")
        case .done:
            return settings.text("Done", "完成")
        case .failed:
            return settings.text("Failed", "失败")
        }
    }

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
    @EnvironmentObject private var appSettings: AppSettingsStore

    let onSettingsTapped: () -> Void
    let onAccountTapped: () -> Void
    let onImportSampleTapped: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("WatchMemo")
                .font(.title.bold())
                .foregroundStyle(Color.wmPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Spacer()

#if DEBUG
            HeaderIconButton(systemName: "square.and.arrow.down", action: onImportSampleTapped, label: t("Import sample", "导入样本"))
#endif
            HeaderIconButton(systemName: "gearshape", action: onSettingsTapped, label: t("Settings", "设置"))
            HeaderIconButton(systemName: "person.circle", action: onAccountTapped, label: t("Account", "账号"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct HeaderIconButton: View {
    let systemName: String
    let action: () -> Void
    let label: String

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.wmSecondaryText)
                .frame(width: 30, height: 30)
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
                .font(.system(size: 12, weight: .medium, design: .monospaced))
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
        .padding(12)
        .background(Color.wmCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecordingFilterControl: View {
    @EnvironmentObject private var appSettings: AppSettingsStore
    @Binding var selection: RecordingFilter

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RecordingFilter.allCases) { filter in
                Button {
                    selection = filter
                } label: {
                    Text(filter.title(using: appSettings))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selection == filter ? Color.wmPrimary : Color.wmSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selection == filter ? Color.wmElevated : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color.wmCard.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RecordingCard: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let recording: InboxRecording
    let draft: TranscriptDraft?
    let obsidianSettings: ObsidianExportSettings
    let isPlaying: Bool
    let isProcessingTranscript: Bool
    let isAudioEnhanced: Bool
    let onOpenTapped: () -> Void
    let onPlayTapped: () -> Void
    let onTranscriptTapped: () -> Void
    let onCopyMarkdownTapped: () -> Void
    let onExportObsidianTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpenTapped) {
                VStack(alignment: .leading, spacing: 14) {
                    cardHeader
                    metadataChips
                    summaryPreview
                    statusArea
                }
            }
            .buttonStyle(.plain)

            if shouldShowActionBar {
                Divider()
                    .overlay(Color.wmDivider)

                actionBar
            }
        }
        .padding(14)
        .background(Color.wmCard)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderColor, lineWidth: recording.status == .transcriptionFailed ? 1 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }

    private var shouldShowActionBar: Bool {
        draft == nil || recording.status == .transcriptionFailed || recording.status == .readyForTranscription
    }

    private var cardHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(recording.status == .transcriptionFailed ? Color.wmSecondaryText.opacity(0.72) : Color.wmText)
                    .lineLimit(2)

                Text(timestampText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.wmSecondaryText)
                    .textCase(.uppercase)
            }

            Spacer()

            VStack(spacing: 10) {
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 9, height: 9)
                    .shadow(color: statusDotColor.opacity(0.45), radius: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.wmSecondaryText)
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var summaryPreview: some View {
        if let summary = draft?.structuredNote?.summary.trimmingCharacters(in: .whitespacesAndNewlines),
           !summary.isEmpty {
            Text(summary)
                .font(.system(size: 14))
                .foregroundStyle(Color.wmSecondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
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

                    Text(t("AI", "AI"))
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

                Text(t("Details", "详情"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.wmSecondaryText)
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
                title: isPlaying ? t("Stop", "停止") : t("Play", "播放"),
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
                    title: t("Copy", "复制"),
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
            return t("Just now", "刚刚")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: recording.createdAt)
    }

    private var sourceIcon: String {
        recording.source == .watchConnectivity ? "applewatch" : "square.and.arrow.down"
    }

    private var sourceText: String {
        recording.source == .watchConnectivity ? t("Watch", "手表") : t("Sim", "模拟")
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
            return t("Ready for AI", "等待 AI 整理")
        case .transcribing:
            return isProcessingTranscript ? t("Processing...", "处理中...") : t("Interrupted. Retry", "已中断，可重试")
        case .draftReady:
            return t("Processed", "已整理")
        case .transcriptionFailed:
            if let message = recording.transcriptionErrorMessage, !message.isEmpty {
                return t("Transcription failed", "整理失败") + ": \(message)"
            }
            return t("Transcription failed", "整理失败")
        case .transcribingLater:
            return t("Queued", "已排队")
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
            return t("Retry", "重试")
        case .draftReady:
            return t("Refresh", "刷新")
        case .readyForTranscription, .transcribingLater:
            return draft == nil ? t("AI", "AI") : t("Refresh", "刷新")
        }
    }

    private var diagnosticText: String {
        var parts: [String] = []

        if let duration = recording.lastTranscriptionDurationSeconds {
            parts.append("\(t("AI", "AI")) \(formatPrecise(duration: duration))")
        }

        if isAudioEnhanced {
            parts.append(t("Enhanced audio", "音频增强"))
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
            "\(t("Text", "文本")) \(metrics.rawCharacterCount)->\(metrics.cleanedCharacterCount)"
        ]

        if let ratio = metrics.compressionRatio {
            parts.append("\(Int((ratio * 100).rounded()))%")
        }

        if metrics.usedSegmentedProcessing || metrics.segmentCount > 1 {
            parts.append("\(t("Segments", "分段")) \(metrics.segmentCount)")
        }

        if metrics.hasSpeakerLabels {
            parts.append("\(t("Speakers", "说话人")) \(metrics.estimatedSpeakerCount)")
        }

        return parts.joined(separator: " ")
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
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

private struct MemoDetailScreen: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let recording: InboxRecording
    let draft: TranscriptDraft?
    let obsidianSettings: ObsidianExportSettings
    let isPlaying: Bool
    let playbackProgress: (currentTime: TimeInterval, duration: TimeInterval)
    let isProcessingTranscript: Bool
    let isAudioEnhanced: Bool
    let onPlayTapped: () -> Void
    let onTranscriptTapped: () -> Void
    let onCopyMarkdownTapped: () -> Void
    let onExportObsidianTapped: () -> Void
    let onArchiveStateTapped: () -> Void

    var body: some View {
        ZStack {
            Color.wmBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailHeader
                    detailMetrics

                    AudioDetailPanel(
                        durationSeconds: recording.durationSeconds,
                        isPlaying: isPlaying,
                        currentTimeSeconds: playbackProgress.currentTime,
                        playbackDurationSeconds: playbackProgress.duration,
                        onPlayTapped: onPlayTapped
                    )

                    if isProcessingTranscript {
                        ProcessingPanel()
                            .environmentObject(appSettings)
                    }

                    if let draft {
                        AIResultDetailView(
                            recording: recording,
                            draft: draft,
                            obsidianSettings: obsidianSettings,
                            onCopyMarkdownTapped: onCopyMarkdownTapped,
                            onExportObsidianTapped: onExportObsidianTapped
                        )
                    } else {
                        EmptyDraftDetail(
                            statusText: statusText,
                            onTranscriptTapped: onTranscriptTapped
                        )
                        .environmentObject(appSettings)
                    }

                    ArchiveStatePanel(
                        isArchived: recording.isArchived,
                        archivedAt: recording.archivedAt,
                        onArchiveStateTapped: onArchiveStateTapped
                    )
                    .environmentObject(appSettings)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(t("Memo", "记录"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.wmText)
                .fixedSize(horizontal: false, vertical: true)

            Text(timestampText)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.wmSecondaryText)
                .textCase(.uppercase)

            if let summary = draft?.structuredNote?.summary.trimmingCharacters(in: .whitespacesAndNewlines),
               !summary.isEmpty {
                Text(summary)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.wmSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailMetrics: some View {
        HStack(spacing: 9) {
            InfoChip(systemName: "clock", text: format(duration: recording.durationSeconds))
            InfoChip(systemName: recording.source == .watchConnectivity ? "applewatch" : "square.and.arrow.down", text: sourceText)
            InfoChip(systemName: "sparkles", text: statusText)
        }
    }

    private var title: String {
        draft?.structuredNote?.title ?? friendlyFileName
    }

    private var friendlyFileName: String {
        recording.originalFileName
            .replacingOccurrences(of: ".m4a", with: "")
            .replacingOccurrences(of: "watchmemo-", with: "")
    }

    private var timestampText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: recording.createdAt)
    }

    private var sourceText: String {
        recording.source == .watchConnectivity ? t("Watch", "手表") : t("Sim", "模拟")
    }

    private var statusText: String {
        switch recording.status {
        case .readyForTranscription:
            return t("Ready", "待整理")
        case .transcribing:
            return t("Processing", "处理中")
        case .draftReady:
            return isAudioEnhanced ? t("Enhanced", "已增强") : t("Done", "完成")
        case .transcriptionFailed:
            return t("Failed", "失败")
        case .transcribingLater:
            return t("Queued", "排队中")
        }
    }

    private func format(duration: TimeInterval) -> String {
        let seconds = max(Int(duration.rounded()), 0)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct ArchiveStatePanel: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let isArchived: Bool
    let archivedAt: Date?
    let onArchiveStateTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: isArchived ? "archivebox.fill" : "archivebox")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.wmCyan)
                .textCase(.uppercase)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.wmSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            CardActionButton(
                systemName: isArchived ? "tray.and.arrow.down" : "archivebox",
                title: isArchived ? t("Restore to Inbox", "恢复到收件箱") : t("Archive Memo", "归档记录"),
                prominent: !isArchived,
                action: onArchiveStateTapped
            )
        }
        .padding(16)
        .background(Color.wmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var title: String {
        isArchived ? t("Archived", "已归档") : t("Inbox", "收件箱")
    }

    private var message: String {
        if isArchived {
            if let archivedAt {
                return t("This memo is archived. You can restore it to the inbox when it needs attention again.", "这条记录已归档。需要重新处理时，可以恢复到收件箱。")
                    + " \(formatted(date: archivedAt))"
            }
            return t("This memo is archived. You can restore it to the inbox when it needs attention again.", "这条记录已归档。需要重新处理时，可以恢复到收件箱。")
        }

        return t(
            "Archive this memo after it has been reviewed, copied, or exported. Audio and AI notes will be kept.",
            "确认、复制或导出后，可以归档这条记录。录音和 AI 内容都会保留。"
        )
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct ProcessingPanel: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(t("AI is organizing this memo", "AI 正在整理这条记录"), systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.wmCyan)

            ProgressView()
                .tint(Color.wmCyan)
        }
        .padding(16)
        .background(Color.wmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct EmptyDraftDetail: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let statusText: String
    let onTranscriptTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(statusText, systemImage: "sparkles")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.wmCyan)
                .textCase(.uppercase)

            Text(t("Create an AI note to see summary, conclusions, action items, and transcript here.", "生成 AI 记录后，这里会展示摘要、关键结论、行动项和原文。"))
                .font(.system(size: 15))
                .foregroundStyle(Color.wmSecondaryText)

            CardActionButton(
                systemName: "sparkles",
                title: t("Create AI Note", "生成 AI 记录"),
                prominent: true,
                action: onTranscriptTapped
            )
        }
        .padding(16)
        .background(Color.wmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct MissingRecordingView: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    var body: some View {
        ZStack {
            Color.wmBackground
                .ignoresSafeArea()
            Text(t("This recording is no longer available.", "这条记录已经不可用。"))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.wmSecondaryText)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct AIResultDetailView: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let recording: InboxRecording
    let draft: TranscriptDraft
    let obsidianSettings: ObsidianExportSettings
    let onCopyMarkdownTapped: () -> Void
    let onExportObsidianTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let note = draft.structuredNote {
                StructuredNoteDetail(note: note)
                ObsidianPreviewCard(note: note, settings: obsidianSettings, createdAt: recording.createdAt)
            } else {
                RawTranscriptDetail(text: draft.cleanedText)
            }

            DetailActionBar(
                onCopyMarkdownTapped: onCopyMarkdownTapped,
                onExportObsidianTapped: onExportObsidianTapped
            )
        }
        .padding(.top, 2)
    }
}

private struct AudioDetailPanel: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let durationSeconds: TimeInterval
    let isPlaying: Bool
    let currentTimeSeconds: TimeInterval
    let playbackDurationSeconds: TimeInterval
    let onPlayTapped: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            WaveformStrip()

            ProgressView(value: clampedCurrentTime, total: effectiveDuration)
                .tint(Color.wmCyan)
                .scaleEffect(x: 1, y: 1.4, anchor: .center)

            HStack(spacing: 18) {
                Text(format(duration: clampedCurrentTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.wmSecondaryText)

                Spacer()

                Button(action: onPlayTapped) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.wmBackground)
                        .frame(width: 50, height: 50)
                        .background(Color.wmText)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? t("Stop playback", "停止播放") : t("Play recording", "播放录音"))

                Spacer()

                Text(format(duration: effectiveDuration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.wmSecondaryText)
            }
        }
        .padding(14)
        .background(Color.wmBackground.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func format(duration: TimeInterval) -> String {
        let seconds = max(Int(duration.rounded()), 0)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var effectiveDuration: TimeInterval {
        let activeDuration = playbackDurationSeconds > 0 ? playbackDurationSeconds : durationSeconds
        return max(activeDuration, 0.1)
    }

    private var clampedCurrentTime: TimeInterval {
        min(max(currentTimeSeconds, 0), effectiveDuration)
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct WaveformStrip: View {
    private let levels: [CGFloat] = [
        0.34, 0.78, 0.48, 0.92, 0.42, 0.68, 0.56, 0.86,
        0.36, 0.72, 0.50, 0.64, 0.44, 0.58, 0.40, 0.74,
        0.46, 0.52, 0.38, 0.62, 0.35, 0.49, 0.31, 0.57
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(levels.indices, id: \.self) { index in
                Capsule()
                    .fill(index < 8 ? Color.wmCyan : Color.wmDivider)
                    .frame(width: 3, height: 38 * levels[index])
            }
        }
        .frame(maxWidth: .infinity, minHeight: 48)
    }
}

private struct StructuredNoteDetail: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let note: StructuredTranscriptNote

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !note.tags.isEmpty {
                TagStrip(tags: note.tags)
            }

            NoteSection(
                title: t("Summary", "摘要"),
                systemName: "doc.text",
                accent: Color.wmCyan,
                content: note.summary
            )

            if !keyConclusions.isEmpty {
                BulletSection(
                    title: t("Key Conclusions", "关键结论"),
                    systemName: "lightbulb",
                    accent: Color.wmGreen,
                    items: keyConclusions
                )
            }

            if !bodyWithoutConclusions.isEmpty {
                NoteSection(
                    title: t("Transcript", "原文"),
                    systemName: "text.alignleft",
                    accent: Color.wmSecondaryText,
                    content: bodyWithoutConclusions,
                    lineLimit: 10
                )
            }

            if !note.actionItems.isEmpty {
                ActionItemsSection(items: note.actionItems)
            }
        }
    }

    private var bodyWithoutConclusions: String {
        splitBody.body
    }

    private var keyConclusions: [String] {
        splitBody.conclusions
    }

    private var splitBody: (body: String, conclusions: [String]) {
        let marker = "## 关键结论"
        guard let range = note.body.range(of: marker) else {
            return (note.body.trimmingCharacters(in: .whitespacesAndNewlines), [])
        }

        let body = note.body[..<range.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let conclusionText = note.body[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let conclusions = conclusionText
            .split(whereSeparator: \.isNewline)
            .map { line in
                String(line)
                    .replacingOccurrences(of: #"^\s*[-•]\s*"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty && $0 != "无明确结论" }

        return (body, conclusions)
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct TagStrip: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
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
}

private struct BulletSection: View {
    let title: String
    let systemName: String
    let accent: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemName)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
                .textCase(.uppercase)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 9) {
                    Circle()
                        .fill(accent)
                        .frame(width: 4, height: 4)
                        .padding(.top, 8)

                    Text(item)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.wmText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(Color.wmElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ActionItemsSection: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(t("Action Items", "行动项"), systemImage: "checklist")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.wmWarning)
                .textCase(.uppercase)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: index == items.count - 1 ? "checkmark.square" : "square")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.wmWarning)
                        .padding(.top, 2)

                    Text(item)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.wmText)
                        .strikethrough(index == items.count - 1 && items.count > 2, color: Color.wmSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(Color.wmElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct RawTranscriptDetail: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let text: String

    var body: some View {
        NoteSection(
            title: t("Transcript", "原文"),
            systemName: "text.alignleft",
            accent: Color.wmSecondaryText,
            content: text,
            lineLimit: 12
        )
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct ObsidianPreviewCard: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let note: StructuredTranscriptNote
    let settings: ObsidianExportSettings
    let createdAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 12, weight: .bold))
                Text(t("Obsidian Preview", "Obsidian 预览"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(Color.wmCyan)

            Text(previewPath)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.wmText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.wmElevated.opacity(0.35), Color.wmBackground.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.wmDivider, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var previewPath: String {
        let folder = settings.folderPath.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        let datePrefix = Self.dateFormatter.string(from: createdAt)
        let fileName = "\(datePrefix)_\(safeFileName(note.title)).md"

        if folder.isEmpty {
            return fileName
        }

        return "\(folder)/\(fileName)"
    }

    private func safeFileName(_ title: String) -> String {
        let invalid = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return title
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct DetailActionBar: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let onCopyMarkdownTapped: () -> Void
    let onExportObsidianTapped: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            CardActionButton(
                systemName: "doc.on.doc",
                title: t("Copy Markdown", "复制 Markdown"),
                prominent: false,
                action: onCopyMarkdownTapped
            )

            CardActionButton(
                systemName: "books.vertical",
                title: t("Export to Obsidian", "导出到 Obsidian"),
                prominent: true,
                action: onExportObsidianTapped
            )
        }
        .padding(8)
        .background(Color.wmBackground.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
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

private struct EmptyMailboxView: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let mailbox: MailboxTab

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: mailbox.emptyIconName)
                .font(.system(size: 48))
                .foregroundStyle(Color.wmCyan)

            Text(mailbox.emptyTitle(using: appSettings))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.wmText)

            Text(mailbox.emptyMessage(using: appSettings))
                .font(.system(size: 15))
                .foregroundStyle(Color.wmSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct EmptyFilterView: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let filter: RecordingFilter
    let mailbox: MailboxTab

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 38))
                .foregroundStyle(Color.wmSecondaryText)

            Text(emptyText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.wmText)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyText: String {
        switch mailbox {
        case .inbox:
            return t("No \(filter.title(using: appSettings).lowercased()) recordings", "没有\(filter.title(using: appSettings))记录")
        case .archive:
            return t("No archived \(filter.title(using: appSettings).lowercased()) recordings", "没有已归档的\(filter.title(using: appSettings))记录")
        }
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct FloatingMemoButton: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "mic.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.wmOnCyan)
                .frame(width: 58, height: 58)
                .background(Color.wmPrimary)
                .clipShape(Circle())
                .shadow(color: Color.wmPrimary.opacity(0.24), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t("Record on iPhone coming soon", "iPhone 录音即将支持"))
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
    }
}

private struct BottomNavBar: View {
    @EnvironmentObject private var appSettings: AppSettingsStore

    let selectedMailbox: MailboxTab
    let onInboxTapped: () -> Void
    let onArchiveTapped: () -> Void
    let onSettingsTapped: () -> Void

    var body: some View {
        HStack {
            BottomNavItem(systemName: "tray.full", title: t("Inbox", "收件箱"), isSelected: selectedMailbox == .inbox, action: onInboxTapped)
            BottomNavItem(systemName: "archivebox", title: t("Archive", "归档"), isSelected: selectedMailbox == .archive, action: onArchiveTapped)
            BottomNavItem(systemName: "gearshape", title: t("Settings", "设置"), isSelected: false, action: onSettingsTapped)
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.wmDivider)
                .frame(height: 1)
        }
    }

    private func t(_ english: String, _ simplifiedChinese: String) -> String {
        appSettings.text(english, simplifiedChinese)
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
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
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

extension Color {
    static let wmBackground = wmDynamic(dark: wmHex(0x0D0D0F), light: wmHex(0xFAF9FE))
    static let wmCard = wmDynamic(dark: wmHex(0x1C1C1F), light: wmHex(0xFFFFFF))
    static let wmElevated = wmDynamic(dark: wmHex(0x2E2E30), light: wmHex(0xF4F3F8))
    static let wmDivider = wmDynamic(dark: wmHex(0x3D474D), light: wmHex(0xC1C6D7))
    static let wmText = wmDynamic(dark: wmHex(0xE3E3E6), light: wmHex(0x1A1B1F))
    static let wmSecondaryText = wmDynamic(dark: wmHex(0xB8C4CC), light: wmHex(0x414755))
    static let wmPrimary = wmDynamic(dark: wmHex(0xBAE8FF), light: wmHex(0x0058BC))
    static let wmCyan = wmDynamic(dark: wmHex(0x63D1FF), light: wmHex(0x0070EB))
    static let wmOnCyan = wmDynamic(dark: wmHex(0x002933), light: wmHex(0xFFFFFF))
    static let wmGreen = wmDynamic(dark: wmHex(0x69FF73), light: wmHex(0x006B27))
    static let wmWarning = wmDynamic(dark: wmHex(0xFFB5AB), light: wmHex(0xBC000A))
    static let wmRed = wmDynamic(dark: wmHex(0xFF453A), light: wmHex(0xBA1A1A))

    private static func wmDynamic(dark: UIColor, light: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func wmHex(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
