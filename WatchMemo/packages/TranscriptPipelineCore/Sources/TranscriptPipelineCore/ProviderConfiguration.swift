import Foundation

public struct ProviderConfiguration: Codable, Equatable, Identifiable, Sendable {
    public enum Kind: String, Codable, Equatable, Sendable {
        case fake
        case openAICompatible
        case localCommand
    }

    public var id: Kind { kind }

    public let kind: Kind
    public let displayName: String
    public let endpointURL: URL?
    public let model: String?
    public let commandPath: String?

    public init(
        kind: Kind,
        displayName: String,
        endpointURL: URL? = nil,
        model: String? = nil,
        commandPath: String? = nil
    ) {
        self.kind = kind
        self.displayName = displayName
        self.endpointURL = endpointURL
        self.model = model
        self.commandPath = commandPath
    }

    public static let fake = ProviderConfiguration(
        kind: .fake,
        displayName: "Fake local provider"
    )
}
