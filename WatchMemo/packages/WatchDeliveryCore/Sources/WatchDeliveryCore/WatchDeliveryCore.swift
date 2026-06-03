import Foundation

public enum DeliveryState: String, Codable, Equatable {
    case recorded
    case sendingToPhone
    case transferredToPhone
    case failed
}

public enum DeliveryRetryPolicy {
    public static func shouldRetry(_ state: DeliveryState) -> Bool {
        switch state {
        case .recorded, .sendingToPhone, .failed:
            return true
        case .transferredToPhone:
            return false
        }
    }
}
