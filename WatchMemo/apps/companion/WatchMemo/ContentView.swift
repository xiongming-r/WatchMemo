import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var receiver: PhoneConnectivityReceiver

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(receiver.statusText)
                        .foregroundStyle(.secondary)
                }

                if receiver.receivedRecordings.isEmpty {
                    ContentUnavailableView(
                        "No recordings yet",
                        systemImage: "waveform",
                        description: Text("Recordings captured on Apple Watch will appear here after transfer.")
                    )
                } else {
                    ForEach(receiver.receivedRecordings) { recording in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recording.fileName)
                                .font(.headline)
                            Text(recording.receivedAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("WatchMemo")
        }
    }
}
