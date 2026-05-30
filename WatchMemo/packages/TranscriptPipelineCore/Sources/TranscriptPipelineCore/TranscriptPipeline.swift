import Foundation

public struct TranscriptPipeline {
    private let provider: any TranscriptProvider
    private let cleaner: any TranscriptCleaning
    private let now: () -> Date

    public init(
        provider: any TranscriptProvider,
        cleaner: any TranscriptCleaning,
        now: @escaping () -> Date = Date.init
    ) {
        self.provider = provider
        self.cleaner = cleaner
        self.now = now
    }

    public func makeDraft(
        recordingID: UUID,
        audioFileURL: URL,
        hint: String? = nil
    ) async throws -> TranscriptDraft {
        let rawText = try await provider.transcribe(audioFileURL: audioFileURL, hint: hint)
        let cleanup = cleaner.clean(rawText)

        return TranscriptDraft(
            id: UUID(),
            recordingID: recordingID,
            rawText: rawText,
            cleanedText: cleanup.cleanedText,
            removedFillers: cleanup.removedFillers,
            createdAt: now(),
            status: .cleaned
        )
    }
}
