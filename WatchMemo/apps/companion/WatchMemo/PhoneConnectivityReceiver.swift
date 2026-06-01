import Foundation
import WatchConnectivity

@MainActor
final class PhoneConnectivityReceiver: NSObject {
    var onImported: ((InboxRecording) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let store: PhoneInboxStore

    init(store: PhoneInboxStore) {
        self.store = store
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else {
            updateStatus("Watch Connectivity unavailable")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        updateStatus(connectivityStatus(for: session, prefix: "Connecting"))
    }

    private func receive(file: WCSessionFile) {
        do {
            let fileName = (file.metadata?["fileName"] as? String) ?? file.fileURL.lastPathComponent
            let metadata = InboxImportMetadata(
                id: UUID(uuidString: file.metadata?["recordingID"] as? String ?? "") ?? UUID(),
                originalFileName: fileName,
                createdAt: createdAt(from: file.metadata),
                durationSeconds: duration(from: file.metadata),
                source: .watchConnectivity
            )
            let imported = try store.importRecording(fileURL: file.fileURL, metadata: metadata)
            onImported?(imported)
            updateStatus("Received \(fileName)")
        } catch {
            updateStatus("Receive failed: \(error.localizedDescription)")
        }
    }

    private func updateStatus(_ text: String) {
        onStatusChange?(text)
    }

    private func connectivityStatus(for session: WCSession, prefix: String) -> String {
        let pairedText = session.isPaired ? "paired" : "not paired"
        let installedText = session.isWatchAppInstalled ? "watch app installed" : "watch app missing"
        return "\(prefix): \(pairedText), \(installedText)"
    }

    private func createdAt(from metadata: [String: Any]?) -> Date {
        guard let interval = metadata?["createdAt"] as? TimeInterval else {
            return Date()
        }

        return Date(timeIntervalSince1970: interval)
    }

    private func duration(from metadata: [String: Any]?) -> TimeInterval {
        guard let duration = metadata?["durationSeconds"] as? TimeInterval else {
            return 0
        }

        return duration
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
                updateStatus("Connection failed: \(error.localizedDescription)")
            } else {
                updateStatus(
                    activationState == .activated
                        ? connectivityStatus(for: session, prefix: "Ready")
                        : connectivityStatus(for: session, prefix: "Waiting")
                )
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        Task { @MainActor in
            receive(file: file)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateStatus(connectivityStatus(for: session, prefix: "Reachability changed"))
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
