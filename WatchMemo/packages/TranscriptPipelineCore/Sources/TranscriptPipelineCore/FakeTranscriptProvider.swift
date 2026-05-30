import Foundation

public protocol TranscriptProvider {
    func transcribe(audioFileURL: URL, hint: String?) async throws -> String
}

public struct FakeTranscriptProvider: TranscriptProvider {
    private let fixedText: String?

    public init(fixedText: String? = nil) {
        self.fixedText = fixedText
    }

    public func transcribe(audioFileURL: URL, hint: String?) async throws -> String {
        if let fixedText {
            return fixedText
        }

        let subject = hint?.isEmpty == false
            ? hint!
            : audioFileURL.deletingPathExtension().lastPathComponent

        return "嗯 我想记录一下 \(subject)，就是先把这条想法保存下来，后面再整理成卡片。"
    }
}
