import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case simplifiedChinese

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var colorScheme: ColorScheme {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }

    func displayName(language: AppLanguage) -> String {
        switch (self, language) {
        case (.dark, .english):
            return "Dark"
        case (.dark, .simplifiedChinese):
            return "暗黑"
        case (.light, .english):
            return "Light"
        case (.light, .simplifiedChinese):
            return "明亮"
        }
    }
}

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            userDefaults.set(language.rawValue, forKey: Self.languageKey)
        }
    }

    @Published var themeMode: AppThemeMode {
        didSet {
            userDefaults.set(themeMode.rawValue, forKey: Self.themeModeKey)
        }
    }

    private let userDefaults: UserDefaults
    private static let languageKey = "watchmemo.appLanguage"
    private static let themeModeKey = "watchmemo.themeMode"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let storedLanguage = userDefaults.string(forKey: Self.languageKey)
            .flatMap(AppLanguage.init(rawValue:))
        self.language = storedLanguage ?? .simplifiedChinese

        let storedThemeMode = userDefaults.string(forKey: Self.themeModeKey)
            .flatMap(AppThemeMode.init(rawValue:))
        self.themeMode = storedThemeMode ?? .dark
    }

    func text(_ english: String, _ simplifiedChinese: String) -> String {
        language == .english ? english : simplifiedChinese
    }
}
