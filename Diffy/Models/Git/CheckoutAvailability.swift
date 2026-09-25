import Foundation

enum CheckoutAvailability: Hashable, Sendable {
    case unknown
    case available
    case needsLocation(CheckoutUnavailableReason)
    case notRepository
    case noCheckout

    var requiresLocation: Bool {

        if case .needsLocation = self {
            return true
        }

        return false

    }
}
