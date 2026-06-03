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
        return makeDraft(recordingID: recordingID, rawText: rawText)
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

        return makeDraft(recordingID: recordingID, rawText: segmentTexts.joined(separator: "\n\n"))
    }

    private func makeDraft(recordingID: UUID, rawText: String) -> TranscriptDraft {
        let cleanup = cleaner.clean(rawText)
        let createdAt = now()

        return TranscriptDraft(
            id: UUID(),
            recordingID: recordingID,
            rawText: rawText,
            cleanedText: cleanup.cleanedText,
            removedFillers: cleanup.removedFillers,
            createdAt: createdAt,
            status: .cleaned,
            structuredNote: noteFormatter.format(text: cleanup.cleanedText, createdAt: createdAt)
        )
    }
}
