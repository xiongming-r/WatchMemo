import Foundation

final class ObsidianSettingsStore {
    private let key = "watchmemo.obsidian.export-settings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ObsidianExportSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(ObsidianExportSettings.self, from: data) else {
            return .default
        }

        return settings
    }

    func save(_ settings: ObsidianExportSettings) throws {
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: key)
    }
}
