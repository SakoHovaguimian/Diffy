import Foundation

/// Reported by a remote refresh so a monitor can choose the next interval.
enum RemoteRefreshOutcome: Hashable, Sendable {
    case changed
    case unchanged
    case failed
    case rateLimited(until: Date?)
    case offline
}
