import Foundation

/// A multi-step Git operation that is paused in the repository.
enum GitOperationState: Codable, Hashable, Sendable {
    case none
    case merging(incoming: String?)
    case rebasing(onto: String?, step: Int?, total: Int?)
    case cherryPicking
    case reverting

    var isInProgress: Bool {
        self != .none
    }

    var title: String {

        switch self {

        case .none: "No operation in progress"
        case .merging: "Merge in progress"
        case .rebasing: "Rebase in progress"
        case .cherryPicking: "Cherry-pick in progress"
        case .reverting: "Revert in progress"

        }

    }

    /// Diffy can continue and abort merges and rebases. Other sequences are shown
    /// so their state is never hidden, but they are finished outside Diffy.
    var supportsContinueAndAbort: Bool {

        switch self {

        case .merging, .rebasing: true
        default: false

        }

    }
}
