import Foundation

enum GitSnapshotScope: Sendable {

    /// HEAD, upstream, file status, and paused operations. References are carried
    /// over from the previous snapshot.
    case status

    /// Status plus remotes, branches, tags, and recent commits.
    case full

}
