import Foundation

public protocol TranscriptCleaning {
    func clean(_ rawText: String) -> TranscriptCleanupResult
}

public struct ConservativeTranscriptCleaner: TranscriptCleaning {
    private let fillers: [String]

    public init(fillers: [String] = ["嗯", "呃", "那个", "就是", "um", "uh", "you know"]) {
        self.fillers = fillers
    }

    public func clean(_ rawText: String) -> TranscriptCleanupResult {
        var text = rawText
        var removedFillers: [(offset: Int, filler: String)] = []

        for filler in fillers {
            let pattern = replacementPattern(for: filler)
            let changed = text
            text = text.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )

            if text != changed {
                let offset = rawText.range(of: filler, options: .caseInsensitive)
                    .map { rawText.distance(from: rawText.startIndex, to: $0.lowerBound) } ?? Int.max
                removedFillers.append((offset, filler))
            }
        }

        text = normalize(text)
        return TranscriptCleanupResult(
            originalText: rawText,
            cleanedText: text,
            removedFillers: removedFillers
                .sorted { $0.offset < $1.offset }
                .map(\.filler)
        )
    }

    private func replacementPattern(for filler: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: filler)
        if filler.range(of: #"^[A-Za-z ]+$"#, options: .regularExpression) != nil {
            return #"\b"# + escaped + #"\b"#
        }

        return escaped
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+([,，。.!?？])"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"([,，])\s*([,，。.!?？])"#, with: "$2", options: .regularExpression)
            .replacingOccurrences(of: #"^[\s,，。.!?？]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
