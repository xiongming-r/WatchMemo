import Foundation
import Testing
@testable import NoteDeliveryCore

@Suite("Obsidian export")
struct ObsidianExportTests {
    @Test("builder creates an Obsidian new note URL with vault folder title and content")
    func builderCreatesNewNoteURL() throws {
        let builder = ObsidianExportURLBuilder(maxContentCharacters: 10_000)
        let payload = ObsidianNotePayload(
            title: "客户/会议: 下一步",
            markdown: "# 客户会议\n\n待办：确认合同。",
            createdAt: fixedDate
        )
        let settings = ObsidianExportSettings(
            vaultName: "Work Vault",
            folderPath: "WatchMemo/Inbox",
            openAfterExport: true
        )

        let url = try builder.makeNewNoteURL(payload: payload, settings: settings)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.scheme == "obsidian")
        #expect(components.host == "new")
        #expect(components.queryItems?.first(named: "vault")?.value == "Work Vault")
        #expect(components.queryItems?.first(named: "name")?.value == "WatchMemo/Inbox/2026-06-02 0800 - 客户 会议 下一步")
        #expect(components.queryItems?.first(named: "content")?.value == payload.markdown)
    }

    @Test("builder omits empty vault and folder")
    func builderOmitsEmptyVaultAndFolder() throws {
        let builder = ObsidianExportURLBuilder(maxContentCharacters: 10_000)
        let payload = ObsidianNotePayload(
            title: "散步想法",
            markdown: "今天想到一个新功能。",
            createdAt: fixedDate
        )
        let settings = ObsidianExportSettings(
            vaultName: "  ",
            folderPath: " ",
            openAfterExport: true
        )

        let url = try builder.makeNewNoteURL(payload: payload, settings: settings)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.queryItems?.first(named: "vault") == nil)
        #expect(components.queryItems?.first(named: "name")?.value == "2026-06-02 0800 - 散步想法")
    }

    @Test("builder refuses long content instead of risking silent truncation")
    func builderRefusesLongContent() throws {
        let builder = ObsidianExportURLBuilder(maxContentCharacters: 12)
        let payload = ObsidianNotePayload(
            title: "长录音",
            markdown: "这是一段超过限制的长文本内容。",
            createdAt: fixedDate
        )

        #expect(throws: ObsidianExportError.contentTooLarge(characterCount: payload.markdown.count, limit: 12)) {
            _ = try builder.makeNewNoteURL(payload: payload, settings: .default)
        }
    }

    @Test("builder refuses empty markdown")
    func builderRefusesEmptyMarkdown() throws {
        let builder = ObsidianExportURLBuilder(maxContentCharacters: 10_000)
        let payload = ObsidianNotePayload(
            title: "空内容",
            markdown: "   \n",
            createdAt: fixedDate
        )

        #expect(throws: ObsidianExportError.emptyMarkdown) {
            _ = try builder.makeNewNoteURL(payload: payload, settings: .default)
        }
    }
}

private let fixedDate = DateComponents(
    calendar: Calendar(identifier: .gregorian),
    timeZone: TimeZone(secondsFromGMT: 0),
    year: 2026,
    month: 6,
    day: 2,
    hour: 8,
    minute: 0
).date!

private extension [URLQueryItem] {
    func first(named name: String) -> URLQueryItem? {
        first { $0.name == name }
    }
}
