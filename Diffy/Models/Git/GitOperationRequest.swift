import Foundation

/// An explicit, user-initiated action that may write to a repository.
enum GitOperationRequest: Hashable, Sendable {
    case fetch(remote: String?)
    case push(GitPushOptions)
    case pull(GitPullStrategy)
    case startRebase(onto: String)
    case continueRebase
    case abortRebase
    case startMerge(branch: String)
    case continueMerge
    case abortMerge
    case stage(paths: [String])
    case unstage(paths: [String])
    case restore(paths: [String])
    case resolveConflict(path: String, choice: GitConflictResolutionChoice, stagesResult: Bool)
    case switchBranch(name: String)

    var title: String {

        switch self {

        case .fetch: "Fetch"
        case let .push(options): options.forceWithLease ? "Force Push with Lease" : (options.setsUpstream ? "Set Upstream and Push" : "Push")
        case let .pull(strategy): "Pull · \(strategy.title)"
        case .startRebase: "Rebase"
        case .continueRebase: "Continue Rebase"
        case .abortRebase: "Abort Rebase"
        case .startMerge: "Merge"
        case .continueMerge: "Continue Merge"
        case .abortMerge: "Abort Merge"
        case .stage: "Stage"
        case .unstage: "Unstage"
        case .restore: "Discard Changes"
        case .resolveConflict: "Resolve Conflict"
        case .switchBranch: "Check Out"

        }

    }

    /// Network operations can be slow and show progress with cancellation.
    var usesNetwork: Bool {

        switch self {

        case .fetch, .push, .pull: true
        default: false

        }

    }
}
