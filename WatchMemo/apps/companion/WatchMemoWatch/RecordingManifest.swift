import Foundation

struct RecordingManifest: Codable, Identifiable, Equatable {
    enum DeliveryState: String, Codable, Equatable {
        case recorded
        case sendingToPhone
        case transferredToPhone
        case failed
    }

    let id: UUID
    let fileName: String
    let createdAt: Date
    let durationSeconds: TimeInterval
    var deliveryState: DeliveryState
    var errorMessage: String?
}
