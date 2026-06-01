import Foundation

public struct ProviderRuntimeSettings: Codable, Equatable, Sendable {
    public enum SelectedProvider: String, Codable, Equatable, Sendable, CaseIterable {
        case fake
        case openAICompatible
    }

    public let selectedProvider: SelectedProvider
    public let endpointURL: URL
    public let model: String

    public init(selectedProvider: SelectedProvider, endpointURL: URL, model: String) {
        self.selectedProvider = selectedProvider
        self.endpointURL = endpointURL
        self.model = model
    }

    public static let `default` = ProviderRuntimeSettings(
        selectedProvider: .fake,
        endpointURL: URL(string: "https://api.openai.com/v1")!,
        model: "gpt-4o-transcribe"
    )

    public static func openAICompatible(endpointURL: URL, model: String) -> ProviderRuntimeSettings {
        ProviderRuntimeSettings(
            selectedProvider: .openAICompatible,
            endpointURL: endpointURL,
            model: model
        )
    }

    public var providerConfiguration: ProviderConfiguration {
        switch selectedProvider {
        case .fake:
            return .fake
        case .openAICompatible:
            return .openAICompatible(endpointURL: endpointURL, model: model)
        }
    }
}
