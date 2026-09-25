import Foundation

enum GitSnapshotScope: Equatable, Sendable {

    /// HEAD, upstream, file status, and paused operations. References are carried
    /// over from the previous snapshot.
    case status

    /// Status and the first 30 branch refs for an interactive initial view.
    case initial

    /// Status plus remotes, branches, tags, and recent commits.
    case full

}
