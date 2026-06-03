import Foundation

public struct StructuredTranscriptNote: Codable, Equatable {
    public let title: String
    public let body: String
    public let summary: String
    public let actionItems: [String]
    public let tags: [String]
    public let markdown: String

    public init(
        title: String,
        body: String,
        summary: String,
        actionItems: [String],
        tags: [String],
        markdown: String
    ) {
        self.title = title
        self.body = body
        self.summary = summary
        self.actionItems = actionItems
        self.tags = tags
        self.markdown = markdown
    }
}

public struct TranscriptNoteFormatter {
    public init() {}

    public func format(text: String, createdAt: Date) -> StructuredTranscriptNote {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let note = makeStructuredMarkdownNote(from: lines, originalText: text, createdAt: createdAt) {
            return note
        }

        let actionItems = extractActionItems(from: lines)
        let tags = extractTags(from: lines)
        let body = lines
            .filter { !isActionItemLine($0) && !isTagLine($0) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let noteBody = body.isEmpty ? text.trimmingCharacters(in: .whitespacesAndNewlines) : body
        let title = makeTitle(from: noteBody)
        let summary = makeSummary(from: noteBody)
        let markdown = makeMarkdown(
            title: title,
            body: noteBody,
            summary: summary,
            actionItems: actionItems,
            tags: tags,
            createdAt: createdAt
        )

        return StructuredTranscriptNote(
            title: title,
            body: noteBody,
            summary: summary,
            actionItems: actionItems,
            tags: tags,
            markdown: markdown
        )
    }

    private func makeStructuredMarkdownNote(
        from lines: [String],
        originalText: String,
        createdAt: Date
    ) -> StructuredTranscriptNote? {
        let title = lines
            .first { $0.hasPrefix("# ") && !$0.hasPrefix("## ") }
            .map(stripMarkdownHeading)
        let sections = markdownSections(from: lines)

        guard title != nil || !sections.isEmpty else {
            return nil
        }

        let summaryText = sectionText(for: "摘要", in: sections)
        let dialogueText = sectionText(for: "对话整理", in: sections)
        let bodyText = sectionText(for: "正文", in: sections)
        let conclusionText = sectionText(for: "关键结论", in: sections)
        let baseBody = dialogueText.isEmpty ? bodyText : dialogueText
        let noteBody: String

        if !baseBody.isEmpty, !conclusionText.isEmpty {
            noteBody = [baseBody, "## 关键结论", conclusionText].joined(separator: "\n")
        } else if !baseBody.isEmpty {
            noteBody = baseBody
        } else if !conclusionText.isEmpty {
            noteBody = conclusionText
        } else {
            noteBody = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let actionItems = actionItemsFromSection(sections["待办"] ?? [])
        let tags = tagsFromSection(sections["标签"] ?? [])
        let resolvedTitle = (title?.isEmpty == false ? title : nil) ?? makeTitle(from: noteBody)
        let resolvedSummary = summaryText.isEmpty ? makeSummary(from: noteBody) : summaryText
        let markdown = makeMarkdown(
            title: resolvedTitle,
            body: noteBody,
            summary: resolvedSummary,
            actionItems: actionItems,
            tags: tags,
            createdAt: createdAt
        )

        return StructuredTranscriptNote(
            title: resolvedTitle,
            body: noteBody,
            summary: resolvedSummary,
            actionItems: actionItems,
            tags: tags,
            markdown: markdown
        )
    }

    private func markdownSections(from lines: [String]) -> [String: [String]] {
        var sections: [String: [String]] = [:]
        var currentHeading: String?

        for line in lines {
            guard line.hasPrefix("## ") else {
                if let currentHeading {
                    sections[currentHeading, default: []].append(line)
                }
                continue
            }

            let heading = stripMarkdownHeading(line)
            currentHeading = heading
            sections[heading, default: []] = sections[heading, default: []]
        }

        return sections
    }

    private func sectionText(for heading: String, in sections: [String: [String]]) -> String {
        (sections[heading] ?? [])
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stripMarkdownHeading(_ line: String) -> String {
        line.replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func actionItemsFromSection(_ lines: [String]) -> [String] {
        lines.map { line in
            stripKnownPrefix(
                from: line,
                prefixes: ["- [ ]", "- [x]", "- [X]", "- ", "待办：", "待办:", "TODO：", "TODO:"]
            )
        }
        .filter { !$0.isEmpty }
    }

    private func tagsFromSection(_ lines: [String]) -> [String] {
        lines
            .flatMap { line in
                stripKnownPrefix(from: line, prefixes: ["标签：", "标签:", "Tags：", "Tags:"])
                    .split { character in
                        character == "," || character == "，" || character == " " || character == "#"
                    }
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            .filter { !$0.isEmpty }
    }

    private func makeTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "未命名记录"
        }

        let separators = CharacterSet(charactersIn: "，,。.!！?？\n")
        let firstPart = trimmed.components(separatedBy: separators).first ?? trimmed
        let compact = firstPart.trimmingCharacters(in: .whitespacesAndNewlines)
        let limited = String(compact.prefix(24))
        return limited.prefix(1).uppercased() + limited.dropFirst()
    }

    private func makeSummary(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "暂无摘要。"
        }

        let sentenceEndings = CharacterSet(charactersIn: "。.!！?？")
        if let range = trimmed.rangeOfCharacter(from: sentenceEndings) {
            let sentence = trimmed[...range.lowerBound]
            return String(sentence).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return String(trimmed.prefix(80))
    }

    private func extractActionItems(from lines: [String]) -> [String] {
        lines.compactMap { line in
            guard isActionItemLine(line) else {
                return nil
            }

            return stripKnownPrefix(
                from: line,
                prefixes: ["待办：", "待办:", "TODO：", "TODO:", "- [ ]"]
            )
        }
        .filter { !$0.isEmpty }
    }

    private func extractTags(from lines: [String]) -> [String] {
        lines
            .filter(isTagLine)
            .flatMap { line in
                stripKnownPrefix(from: line, prefixes: ["标签：", "标签:", "Tags：", "Tags:"])
                    .split { character in
                        character == "," || character == "，" || character == " " || character == "#"
                    }
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            .filter { !$0.isEmpty }
    }

    private func isActionItemLine(_ line: String) -> Bool {
        ["待办：", "待办:", "TODO：", "TODO:", "- [ ]"].contains { line.hasPrefix($0) }
    }

    private func isTagLine(_ line: String) -> Bool {
        ["标签：", "标签:", "Tags：", "Tags:"].contains { line.hasPrefix($0) }
    }

    private func stripKnownPrefix(from line: String, prefixes: [String]) -> String {
        var stripped = line
        for prefix in prefixes where stripped.hasPrefix(prefix) {
            stripped.removeFirst(prefix.count)
            break
        }

        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeMarkdown(
        title: String,
        body: String,
        summary: String,
        actionItems: [String],
        tags: [String],
        createdAt: Date
    ) -> String {
        var sections = [
            "# \(title)",
            "",
            "记录时间：\(formatted(date: createdAt))",
            "",
            "## 摘要",
            summary,
            "",
            "## 正文",
            body
        ]

        if !actionItems.isEmpty {
            sections.append("")
            sections.append("## 待办")
            sections.append(contentsOf: actionItems.map { "- [ ] \($0)" })
        }

        if !tags.isEmpty {
            sections.append("")
            sections.append("## 标签")
            sections.append(tags.map { "#\($0)" }.joined(separator: " "))
        }

        return sections.joined(separator: "\n")
    }

    private func formatted(date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
