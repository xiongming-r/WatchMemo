import Foundation
import WatchConnectivity

final class IPhoneRelayTransport: NSObject, RecordingDeliveryTransport {
    static let shared = IPhoneRelayTransport()

    var onTransferFinished: ((RecordingManifest.ID, Error?) -> Void)?

    private let session: WCSession?

    private override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }

        super.init()

        session?.delegate = self
        session?.activate()
    }

    func send(recording: RecordingManifest, fileURL: URL) async throws {
        guard let session else {
            throw RelayError.sessionUnsupported
        }

        guard session.activationState == .activated else {
            session.activate()
            throw RelayError.sessionNotActivated
        }

        let metadata: [String: Any] = [
            "recordingID": recording.id.uuidString,
            "createdAt": recording.createdAt.timeIntervalSince1970,
            "durationSeconds": recording.durationSeconds,
            "fileName": recording.fileName
        ]

        session.transferFile(fileURL, metadata: metadata)
    }
}

extension IPhoneRelayTransport: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        guard let idString = fileTransfer.file.metadata?["recordingID"] as? String,
              let id = UUID(uuidString: idString) else {
            return
        }

        onTransferFinished?(id, error)
    }
}

private enum RelayError: LocalizedError {
    case sessionUnsupported
    case sessionNotActivated

    var errorDescription: String? {
        switch self {
        case .sessionUnsupported:
            return "Watch Connectivity is not supported"
        case .sessionNotActivated:
            return "Watch Connectivity is not ready"
        }
    }
}
