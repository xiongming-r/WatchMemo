import Foundation

public struct ImportAcknowledgementMessage: Equatable {
    public static let messageType = "watchmemo.importAcknowledged"

    public let recordingID: UUID

    public var dictionary: [String: Any] {
        [
            "type": Self.messageType,
            "recordingID": recordingID.uuidString
        ]
    }

    public init(recordingID: UUID) {
        self.recordingID = recordingID
    }

    public init?(dictionary: [String: Any]) {
        guard dictionary["type"] as? String == Self.messageType,
              let idString = dictionary["recordingID"] as? String,
              let recordingID = UUID(uuidString: idString) else {
            return nil
        }

        self.recordingID = recordingID
    }
}
