import Foundation

/// Whether the tracked upstream still matches its branch on the remote.
enum GitUpstreamRemoteState: Equatable, Sendable {
    case checking
    case current
    case changed
    case unavailable
}
