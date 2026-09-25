import Foundation

/// How a pull integrates fetched commits. Diffy always shows the chosen strategy.
enum GitPullStrategy: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case fastForwardOnly
    case rebase
    case merge

    var id: String {
        self.rawValue
    }

    var title: String {

        switch self {

        case .fastForwardOnly: "Fast-Forward Only"
        case .rebase: "Rebase"
        case .merge: "Merge"

        }

    }

    var explanation: String {

        switch self {

        case .fastForwardOnly: "Update only when no local commits need to be combined."
        case .rebase: "Replay your local commits on top of the fetched commits."
        case .merge: "Combine the fetched commits with a merge commit."

        }

    }
}
