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

public enum OpenAICompatibleTranscriptProviderError: Error, Equatable {
    case invalidConfiguration
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case missingTranscriptText
}

public final class OpenAICompatibleTranscriptProvider: TranscriptProvider {
    private let configuration: ProviderConfiguration
    private let apiKey: String
    private let httpClient: any TranscriptHTTPClient
    private let boundary: String

    public init(
        configuration: ProviderConfiguration,
        apiKey: String,
        httpClient: any TranscriptHTTPClient = URLSessionTranscriptHTTPClient(),
        boundary: String = "WatchMemo-\(UUID().uuidString)"
    ) {
        self.configuration = configuration
        self.apiKey = apiKey
        self.httpClient = httpClient
        self.boundary = boundary
    }

    public func transcribe(audioFileURL: URL, hint: String?) async throws -> String {
        guard configuration.kind == .openAICompatible,
              let endpointURL = configuration.endpointURL else {
            throw OpenAICompatibleTranscriptProviderError.invalidConfiguration
        }

        let model = configuration.model ?? "gpt-4o-transcribe"
        let requestURL = endpointURL
            .appendingPathComponent("audio")
            .appendingPathComponent("transcriptions")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = try makeMultipartBody(
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

    private func makeMultipartBody(audioFileURL: URL, model: String, hint: String?) throws -> Data {
        var body = Data()

        appendField(name: "model", value: model, to: &body)
        appendField(name: "response_format", value: "json", to: &body)

        if let hint, !hint.isEmpty {
            appendField(name: "prompt", value: hint, to: &body)
        }

        let fileName = audioFileURL.lastPathComponent
        let fileData = try Data(contentsOf: audioFileURL)
        appendFile(name: "file", fileName: fileName, data: fileData, to: &body)
        body.appendString("--\(boundary)--\r\n")
        return body
    }

    private func appendField(name: String, value: String, to body: inout Data) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }

    private func appendFile(name: String, fileName: String, data: Data, to body: inout Data) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: application/octet-stream\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }

    private func transcriptText(from data: Data) throws -> String? {
        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return response.text
    }

    private func errorMessage(from data: Data) -> String {
        if let response = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return response.error.message
        }

        return String(data: data, encoding: .utf8) ?? "Unknown provider error"
    }
}

private struct TranscriptionResponse: Decodable {
    let text: String?
}

private struct ErrorResponse: Decodable {
    struct ProviderError: Decodable {
        let message: String
    }

    let error: ProviderError
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
