import SwiftUI

@main
struct WatchMemoApp: App {
    @StateObject private var inbox = PhoneInboxViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(inbox)
                .task {
                    inbox.start()
                }
        }
    }
}
