import Foundation

actor LocalRecordingStore {
    private let fileManager: FileManager
    private let documentsDirectory: URL
    private let recordingsDirectory: URL
    private let manifestURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.recordingsDirectory = documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
        self.manifestURL = documentsDirectory.appendingPathComponent("recordings.json")
    }

    func makeRecordingURL(createdAt: Date = Date()) throws -> URL {
        try ensureRecordingsDirectoryExists()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: createdAt).replacingOccurrences(of: ":", with: "-")
        return recordingsDirectory.appendingPathComponent("watchmemo-\(timestamp).m4a")
    }

    func enqueueRecording(fileURL: URL, createdAt: Date, durationSeconds: TimeInterval) throws -> RecordingManifest {
        try ensureRecordingsDirectoryExists()

        let recording = RecordingManifest(
            id: UUID(),
            fileName: fileURL.lastPathComponent,
            createdAt: createdAt,
            durationSeconds: durationSeconds,
            deliveryState: .recorded,
            errorMessage: nil
        )

        var recordings = try loadRecordings()
        recordings.append(recording)
        try save(recordings)
        return recording
    }

    func loadRecordings() throws -> [RecordingManifest] {
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return []
        }

        let data = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([RecordingManifest].self, from: data)
    }

    func fileURL(for recording: RecordingManifest) -> URL {
        recordingsDirectory.appendingPathComponent(recording.fileName)
    }

    func updateRecording(
        id: RecordingManifest.ID,
        deliveryState: RecordingManifest.DeliveryState,
        errorMessage: String? = nil
    ) throws {
        var recordings = try loadRecordings()

        guard let index = recordings.firstIndex(where: { $0.id == id }) else {
            return
        }

        recordings[index].deliveryState = deliveryState
        recordings[index].errorMessage = errorMessage
        try save(recordings)
    }

    private func ensureRecordingsDirectoryExists() throws {
        guard !fileManager.fileExists(atPath: recordingsDirectory.path) else {
            return
        }

        try fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
    }

    private func save(_ recordings: [RecordingManifest]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(recordings)
        try data.write(to: manifestURL, options: .atomic)
    }
}
