import Foundation

public struct ObsidianExportSettings: Codable, Equatable, Sendable {
    public var vaultName: String
    public var folderPath: String
    public var openAfterExport: Bool

    public init(
        vaultName: String,
        folderPath: String,
        openAfterExport: Bool
    ) {
        self.vaultName = vaultName
        self.folderPath = folderPath
        self.openAfterExport = openAfterExport
    }

    public static let `default` = ObsidianExportSettings(
        vaultName: "",
        folderPath: "WatchMemo/Inbox",
        openAfterExport: true
    )
}

public struct ObsidianNotePayload: Equatable, Sendable {
    public let title: String
    public let markdown: String
    public let createdAt: Date

    public init(title: String, markdown: String, createdAt: Date) {
        self.title = title
        self.markdown = markdown
        self.createdAt = createdAt
    }
}

public enum ObsidianExportError: Error, Equatable, LocalizedError, Sendable {
    case emptyMarkdown
    case contentTooLarge(characterCount: Int, limit: Int)
    case invalidURL

    public var errorDescription: String? {
        switch self {
        case .emptyMarkdown:
            return "Markdown content is empty"
        case let .contentTooLarge(characterCount, limit):
            return "Markdown is too long for Obsidian URI export (\(characterCount)/\(limit) characters)"
        case .invalidURL:
            return "Could not build Obsidian URL"
        }
    }
}

public struct ObsidianExportURLBuilder: Sendable {
    public static let defaultMaxContentCharacters = 12_000

    public let maxContentCharacters: Int

    public init(maxContentCharacters: Int = Self.defaultMaxContentCharacters) {
        self.maxContentCharacters = maxContentCharacters
    }

    public func makeNewNoteURL(
        payload: ObsidianNotePayload,
        settings: ObsidianExportSettings
    ) throws -> URL {
        let markdown = payload.markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !markdown.isEmpty else {
            throw ObsidianExportError.emptyMarkdown
        }

        guard markdown.count <= maxContentCharacters else {
            throw ObsidianExportError.contentTooLarge(
                characterCount: markdown.count,
                limit: maxContentCharacters
            )
        }

        var queryItems = [
            URLQueryItem(
                name: "name",
                value: makeNotePath(
                    title: payload.title,
                    createdAt: payload.createdAt,
                    folderPath: settings.folderPath
                )
            ),
            URLQueryItem(name: "content", value: markdown)
        ]

        let vaultName = settings.vaultName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !vaultName.isEmpty {
            queryItems.insert(URLQueryItem(name: "vault", value: vaultName), at: 0)
        }

        var components = URLComponents()
        components.scheme = "obsidian"
        components.host = "new"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ObsidianExportError.invalidURL
        }

        return url
    }

    public func makeNotePath(title: String, createdAt: Date, folderPath: String) -> String {
        let noteName = "\(formatted(createdAt)) - \(sanitizedTitle(title))"
        let folder = normalizedFolderPath(folderPath)

        guard !folder.isEmpty else {
            return noteName
        }

        return "\(folder)/\(noteName)"
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HHmm"
        return formatter.string(from: date)
    }

    private func normalizedFolderPath(_ folderPath: String) -> String {
        folderPath
            .split(separator: "/")
            .map { sanitizedPathComponent(String($0)) }
            .filter { !$0.isEmpty }
            .joined(separator: "/")
    }

    private func sanitizedTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "Untitled WatchMemo Note" : trimmed
        return sanitizedPathComponent(fallback)
    }

    private func sanitizedPathComponent(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:#[]|?*")
            .union(.newlines)
            .union(.controlCharacters)

        let cleanedScalars = value.unicodeScalars.map { scalar in
            invalidCharacters.contains(scalar) ? " " : String(scalar)
        }.joined()

        return cleanedScalars
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
