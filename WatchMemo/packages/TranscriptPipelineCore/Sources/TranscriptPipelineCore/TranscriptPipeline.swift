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
