import Foundation

public struct TranscriptPipeline {
    private let provider: any TranscriptProvider
    private let cleaner: any TranscriptCleaning
    private let noteFormatter: TranscriptNoteFormatter
    private let now: () -> Date

    public init(
        provider: any TranscriptProvider,
        cleaner: any TranscriptCleaning,
        noteFormatter: TranscriptNoteFormatter = TranscriptNoteFormatter(),
        now: @escaping () -> Date = Date.init
    ) {
        self.provider = provider
        self.cleaner = cleaner
        self.noteFormatter = noteFormatter
        self.now = now
    }

    public func makeDraft(
        recordingID: UUID,
        audioFileURL: URL,
        hint: String? = nil
    ) async throws -> TranscriptDraft {
        let rawText = try await provider.transcribe(audioFileURL: audioFileURL, hint: hint)
        return makeDraft(
            recordingID: recordingID,
            rawText: rawText,
            segmentCount: 1,
            usedSegmentedProcessing: false
        )
    }

    public func makeDraftFromSegments(
        recordingID: UUID,
        segmentFileURLs: [URL],
        hint: String? = nil
    ) async throws -> TranscriptDraft {
        var segmentTexts: [String] = []

        for (index, segmentURL) in segmentFileURLs.enumerated() {
            let segmentHint = [
                hint,
                "segment \(index + 1) of \(segmentFileURLs.count)"
            ]
                .compactMap { $0 }
                .joined(separator: " - ")
            let text = try await provider.transcribe(audioFileURL: segmentURL, hint: segmentHint)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !text.isEmpty {
                segmentTexts.append(text)
            }
        }

        return makeDraft(
            recordingID: recordingID,
            rawText: segmentTexts.joined(separator: "\n\n"),
            segmentCount: segmentFileURLs.count,
            usedSegmentedProcessing: true
        )
    }

    private func makeDraft(
        recordingID: UUID,
        rawText: String,
        segmentCount: Int,
        usedSegmentedProcessing: Bool
    ) -> TranscriptDraft {
        let cleanup = cleaner.clean(rawText)
        let createdAt = now()
        let metrics = TranscriptQualityMetrics(
            rawCharacterCount: rawText.count,
            cleanedCharacterCount: cleanup.cleanedText.count,
            compressionRatio: rawText.isEmpty ? nil : Double(cleanup.cleanedText.count) / Double(rawText.count),
            removedFillerCount: cleanup.removedFillers.count,
            segmentCount: segmentCount,
            usedSegmentedProcessing: usedSegmentedProcessing,
            speakerLabels: Self.detectSpeakerLabels(in: cleanup.cleanedText)
        )

        return TranscriptDraft(
            id: UUID(),
            recordingID: recordingID,
            rawText: rawText,
            cleanedText: cleanup.cleanedText,
            removedFillers: cleanup.removedFillers,
            createdAt: createdAt,
            status: .cleaned,
            structuredNote: noteFormatter.format(text: cleanup.cleanedText, createdAt: createdAt),
            qualityMetrics: metrics
        )
    }

    private static func detectSpeakerLabels(in text: String) -> [String] {
        let pattern = #"(?m)^\s*(说话人\s*[A-Za-z0-9一二三四五六七八九十]+|Speaker\s*[A-Za-z0-9]+)\s*[:：]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var labels: [String] = []

        for match in regex.matches(in: text, range: range) {
            guard match.numberOfRanges > 1,
                  let labelRange = Range(match.range(at: 1), in: text) else {
                continue
            }

            let label = text[labelRange]
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !labels.contains(label) {
                labels.append(label)
            }
        }

        return labels
    }
}
