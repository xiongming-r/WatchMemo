import Foundation
import Testing
@testable import WatchMemoMessageCore

@Suite("Import acknowledgement message")
struct ImportAcknowledgementMessageTests {
    @Test("builds a WatchConnectivity-safe dictionary")
    func buildsDictionary() throws {
        let id = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))

        let dictionary = ImportAcknowledgementMessage(recordingID: id).dictionary

        #expect(dictionary["type"] as? String == "watchmemo.importAcknowledged")
        #expect(dictionary["recordingID"] as? String == id.uuidString)
    }

    @Test("parses a valid acknowledgement dictionary")
    func parsesDictionary() throws {
        let id = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))

        let message = ImportAcknowledgementMessage(dictionary: [
            "type": "watchmemo.importAcknowledged",
            "recordingID": id.uuidString
        ])

        #expect(message?.recordingID == id)
    }

    @Test("rejects invalid acknowledgement dictionaries")
    func rejectsInvalidDictionary() {
        #expect(ImportAcknowledgementMessage(dictionary: ["type": "other"]) == nil)
        #expect(ImportAcknowledgementMessage(dictionary: [
            "type": "watchmemo.importAcknowledged",
            "recordingID": "not-a-uuid"
        ]) == nil)
    }
}
