import Foundation
import WatchConnectivity

final class IPhoneRelayTransport: NSObject, RecordingDeliveryTransport {
    static let shared = IPhoneRelayTransport()

    var onTransferFinished: ((RecordingManifest.ID, Error?) -> Void)?
    var onImportAcknowledged: ((RecordingManifest.ID) -> Void)?

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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let acknowledgement = ImportAcknowledgementMessage(dictionary: userInfo) else {
            return
        }

        onImportAcknowledged?(acknowledgement.recordingID)
    }
}

private struct ImportAcknowledgementMessage {
    static let messageType = "watchmemo.importAcknowledged"

    let recordingID: UUID

    init?(dictionary: [String: Any]) {
        guard dictionary["type"] as? String == Self.messageType,
              let idString = dictionary["recordingID"] as? String,
              let recordingID = UUID(uuidString: idString) else {
            return nil
        }

        self.recordingID = recordingID
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
