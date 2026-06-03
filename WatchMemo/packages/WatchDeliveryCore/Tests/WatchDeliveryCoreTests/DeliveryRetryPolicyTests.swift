import Testing
@testable import WatchDeliveryCore

@Suite("Delivery retry policy")
struct DeliveryRetryPolicyTests {
    @Test("retries states that still need an iPhone import acknowledgement")
    func retriesUnconfirmedStates() {
        #expect(DeliveryRetryPolicy.shouldRetry(.recorded))
        #expect(DeliveryRetryPolicy.shouldRetry(.sendingToPhone))
        #expect(DeliveryRetryPolicy.shouldRetry(.failed))
    }

    @Test("does not retry recordings already acknowledged by iPhone import")
    func doesNotRetryAcknowledgedState() {
        #expect(!DeliveryRetryPolicy.shouldRetry(.transferredToPhone))
    }
}
