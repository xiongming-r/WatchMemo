import Foundation

final class ProviderSettingsStore {
    private let key = "watchmemo.provider.runtime-settings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ProviderRuntimeSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(ProviderRuntimeSettings.self, from: data) else {
            return .default
        }

        return settings
    }

    func save(_ settings: ProviderRuntimeSettings) throws {
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: key)
    }
}
