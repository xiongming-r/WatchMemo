import SwiftUI

@main
struct WatchMemoApp: App {
    @StateObject private var receiver = PhoneConnectivityReceiver()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(receiver)
                .task {
                    receiver.start()
                }
        }
    }
}
