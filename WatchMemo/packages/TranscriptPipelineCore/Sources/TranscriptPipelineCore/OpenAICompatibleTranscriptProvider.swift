import Foundation

public protocol TranscriptHTTPClient: AnyObject {
    func data(for request: URLRequest, body: Data) async throws -> (Data, HTTPURLResponse)
}

public final class URLSessionTranscriptHTTPClient: TranscriptHTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest, body: Data) async throws -> (Data, HTTPURLResponse) {
        var request = request
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAICompatibleTranscriptProviderError.invalidResponse
        }

        return (data, httpResponse)
    }
}

public enum OpenAICompatibleTranscriptProviderError: LocalizedError, Equatable {
    case invalidConfiguration
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case missingTranscriptText

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "OpenAI-compatible provider settings are incomplete"
        case .invalidResponse:
            return "Provider returned an invalid response"
        case .requestFailed(let statusCode, let message):
            return "Provider request failed (\(statusCode)): \(message)"
        case .missingTranscriptText:
            return "Provider response did not include transcript text"
        }
    }
}

public final class OpenAICompatibleTranscriptProvider: TranscriptProvider {
    public static let defaultNoteInstruction = """
    请只依据音频中可辨认的人声内容生成记录文本，在不改变原意的前提下，去除语气词、无意义停顿、重复表达、打磕巴和明显口误，输出适合记录到知识库的清晰中文文本。
    如果音频中能清楚区分多位说话人，请用“说话人 A：”“说话人 B：”这类标签组织对话；如果无法可靠区分，或者只有一个人在表达，不要强行标注说话人。
    可以把口语改写成更精准的书面表达，但必须保留原意、判断边界、待确认事项和重要语气。
    如果音频没有可辨认人声、听不清、或内容不足，请只输出：无法从音频中识别出明确人声内容。
    不要编造会议、人名、时间、任务、客户、合同或任何音频中没有出现的信息。只输出整理后的正文。
    """

    private let configuration: ProviderConfiguration
    private let apiKey: String
    private let httpClient: any TranscriptHTTPClient
    private let noteInstruction: String

    public init(
        configuration: ProviderConfiguration,
        apiKey: String,
        httpClient: any TranscriptHTTPClient = URLSessionTranscriptHTTPClient(),
        noteInstruction: String = OpenAICompatibleTranscriptProvider.defaultNoteInstruction
    ) {
        self.configuration = configuration
        self.apiKey = apiKey
        self.httpClient = httpClient
        self.noteInstruction = noteInstruction
    }

    public func transcribe(audioFileURL: URL, hint: String?) async throws -> String {
        guard configuration.kind == .openAICompatible,
              let endpointURL = configuration.endpointURL else {
            throw OpenAICompatibleTranscriptProviderError.invalidConfiguration
        }

        let model = configuration.model ?? "mimo-v2.5"
        let requestURL = endpointURL
            .appendingPathComponent("chat")
            .appendingPathComponent("completions")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = try makeChatCompletionBody(
            audioFileURL: audioFileURL,
            model: model,
            hint: hint
        )
        let (data, response) = try await httpClient.data(for: request, body: body)

        guard (200..<300).contains(response.statusCode) else {
            throw OpenAICompatibleTranscriptProviderError.requestFailed(
                statusCode: response.statusCode,
                message: errorMessage(from: data)
            )
        }

        guard let text = try transcriptText(from: data) else {
            throw OpenAICompatibleTranscriptProviderError.missingTranscriptText
        }

        return text
    }

    private func makeChatCompletionBody(audioFileURL: URL, model: String, hint: String?) throws -> Data {
        let fileData = try Data(contentsOf: audioFileURL)
        let format = audioFileURL.pathExtension.lowercased().isEmpty
            ? "m4a"
            : audioFileURL.pathExtension.lowercased()
        let dataURI = "data:\(mimeType(for: format));base64,\(fileData.base64EncodedString())"
        let userText = [
            "录音线索（只用于识别文件，不可作为正文依据）：\(hint ?? audioFileURL.lastPathComponent)",
            "请根据音频内容生成最终记录文本。"
        ].joined(separator: "\n")

        let payload = ChatCompletionRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: .text(noteInstruction)),
                ChatMessage(
                    role: "user",
                    content: .parts([
                        .text(userText),
                        .inputAudio(dataURI: dataURI)
                    ])
                )
            ],
            temperature: 0.1
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return try encoder.encode(payload)
    }

    private func transcriptText(from data: Data) throws -> String? {
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let message = response.choices.first?.message
        return [message?.content, message?.reasoningContent]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private func errorMessage(from data: Data) -> String {
        if let response = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return response.error.message
        }

        return String(data: data, encoding: .utf8) ?? "Unknown provider error"
    }

    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension {
        case "m4a":
            return "audio/m4a"
        case "mp3", "mpeg":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "caf":
            return "audio/x-caf"
        default:
            return "application/octet-stream"
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Encodable {
    let role: String
    let content: ChatContent
}

private enum ChatContent: Encodable {
    case text(String)
    case parts([ChatContentPart])

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let text):
            var container = encoder.singleValueContainer()
            try container.encode(text)
        case .parts(let parts):
            var container = encoder.singleValueContainer()
            try container.encode(parts)
        }
    }
}

private struct ChatContentPart: Encodable {
    let type: String
    let text: String?
    let input_audio: InputAudio?

    static func text(_ text: String) -> ChatContentPart {
        ChatContentPart(type: "text", text: text, input_audio: nil)
    }

    static func inputAudio(dataURI: String) -> ChatContentPart {
        ChatContentPart(
            type: "input_audio",
            text: nil,
            input_audio: InputAudio(data: dataURI)
        )
    }
}

private struct InputAudio: Encodable {
    let data: String
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
            let reasoningContent: String?

            enum CodingKeys: String, CodingKey {
                case content
                case reasoningContent = "reasoning_content"
            }
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct ErrorResponse: Decodable {
    struct ProviderError: Decodable {
        let message: String
    }

    let error: ProviderError
}
