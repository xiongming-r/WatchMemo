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

    private func receive(stagedFileURL: URL, metadata rawMetadata: [String: Any]?, fallbackFileName: String) {
        do {
            defer {
                try? FileManager.default.removeItem(at: stagedFileURL)
            }

            let fileName = (rawMetadata?["fileName"] as? String) ?? fallbackFileName
            let metadata = InboxImportMetadata(
                id: UUID(uuidString: rawMetadata?["recordingID"] as? String ?? "") ?? UUID(),
                originalFileName: fileName,
                createdAt: createdAt(from: rawMetadata),
                durationSeconds: duration(from: rawMetadata),
                source: .watchConnectivity
            )
            let imported = try store.importRecording(fileURL: stagedFileURL, metadata: metadata)
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

    nonisolated private static func stageReceivedFile(_ file: WCSessionFile) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WatchMemoReceivedFiles", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileName = (file.metadata?["fileName"] as? String) ?? file.fileURL.lastPathComponent
        let fileExtension = URL(fileURLWithPath: fileName).pathExtension
        let destination = directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension.isEmpty ? "m4a" : fileExtension)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.copyItem(at: file.fileURL, to: destination)
        return destination
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
        let metadata = file.metadata
        let fallbackFileName = file.fileURL.lastPathComponent

        let stagedFileURL: URL
        do {
            stagedFileURL = try Self.stageReceivedFile(file)
        } catch {
            Task { @MainActor in
                updateStatus("Receive failed: \(error.localizedDescription)")
            }
            return
        }

        Task { @MainActor in
            receive(
                stagedFileURL: stagedFileURL,
                metadata: metadata,
                fallbackFileName: fallbackFileName
            )
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
