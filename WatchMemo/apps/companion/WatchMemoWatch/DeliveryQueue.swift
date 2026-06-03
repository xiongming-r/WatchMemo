import Foundation

protocol RecordingDeliveryTransport {
    func send(recording: RecordingManifest, fileURL: URL) async throws
}

actor DeliveryQueue {
    private let store: LocalRecordingStore
    private let transport: RecordingDeliveryTransport?

    init(store: LocalRecordingStore, transport: RecordingDeliveryTransport? = nil) {
        self.store = store
        self.transport = transport
    }

    func enqueue(fileURL: URL, createdAt: Date, durationSeconds: TimeInterval) async throws -> RecordingManifest {
        let recording = try await store.enqueueRecording(
            fileURL: fileURL,
            createdAt: createdAt,
            durationSeconds: durationSeconds
        )

        guard let transport else {
            return recording
        }

        await attemptDelivery(recording, transport: transport)
        return recording
    }

    func retryPending() async {
        guard let transport else {
            return
        }

        let recordings: [RecordingManifest]
        do {
            recordings = try await store.loadRecordings()
        } catch {
            return
        }

        for recording in recordings where shouldRetry(recording.deliveryState) {
            await attemptDelivery(recording, transport: transport)
        }
    }

    private func shouldRetry(_ state: RecordingManifest.DeliveryState) -> Bool {
        switch state {
        case .recorded, .sendingToPhone, .failed:
            return true
        case .transferredToPhone:
            return false
        }
    }

    private func attemptDelivery(
        _ recording: RecordingManifest,
        transport: RecordingDeliveryTransport
    ) async {
        do {
            try await store.updateRecording(id: recording.id, deliveryState: .sendingToPhone)
            try await transport.send(recording: recording, fileURL: await store.fileURL(for: recording))
        } catch {
            try? await store.updateRecording(
                id: recording.id,
                deliveryState: .failed,
                errorMessage: error.localizedDescription
            )
        }
    }
}
