import SwiftUI

@main
struct WatchMemoApp: App {
    @StateObject private var inbox = PhoneInboxViewModel()
    @StateObject private var appSettings = AppSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(inbox)
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.themeMode.colorScheme)
                .task {
                    inbox.start()
                }
        }
    }
}
