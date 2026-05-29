import Foundation
import WatchConnectivity

struct ReceivedRecording: Identifiable, Equatable {
    let id: UUID
    let fileName: String
    let receivedAt: Date
    let durationSeconds: TimeInterval?
}

@MainActor
final class PhoneConnectivityReceiver: NSObject, ObservableObject {
    @Published private(set) var receivedRecordings: [ReceivedRecording] = []
    @Published private(set) var statusText = "Waiting for watch"

    private let fileManager: FileManager
    private let inboxDirectory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.inboxDirectory = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Inbox", isDirectory: true)
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else {
            statusText = "Watch Connectivity unavailable"
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        statusText = "Connecting to watch"
    }

    private func receive(file: WCSessionFile) {
        do {
            try ensureInboxExists()

            let fileName = (file.metadata?["fileName"] as? String) ?? file.fileURL.lastPathComponent
            let destination = inboxDirectory.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }

            try fileManager.copyItem(at: file.fileURL, to: destination)

            let received = ReceivedRecording(
                id: UUID(uuidString: file.metadata?["recordingID"] as? String ?? "") ?? UUID(),
                fileName: fileName,
                receivedAt: Date(),
                durationSeconds: file.metadata?["durationSeconds"] as? TimeInterval
            )
            receivedRecordings.insert(received, at: 0)
            statusText = "Received \(receivedRecordings.count) recording\(receivedRecordings.count == 1 ? "" : "s")"
        } catch {
            statusText = "Receive failed: \(error.localizedDescription)"
        }
    }

    private func ensureInboxExists() throws {
        guard !fileManager.fileExists(atPath: inboxDirectory.path) else {
            return
        }

        try fileManager.createDirectory(at: inboxDirectory, withIntermediateDirectories: true)
    }
}

extension PhoneConnectivityReceiver: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                statusText = "Connection failed: \(error.localizedDescription)"
            } else {
                statusText = activationState == .activated ? "Ready for watch" : "Waiting for watch"
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        Task { @MainActor in
            receive(file: file)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
