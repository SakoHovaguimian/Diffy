import Foundation

extension GitOperationRequest {

    var showsChangeSummary: Bool {

        switch self {

        case .pull, .fetch, .startMerge, .continueMerge, .startRebase, .continueRebase, .switchBranch:
            true

        default:
            false

        }

    }

    var summaryTitle: String {

        switch self {

        case .pull: "Pull complete"
        case .fetch: "Fetch complete"
        case .startMerge, .continueMerge: "Merge complete"
        case .startRebase, .continueRebase: "Rebase complete"
        case .switchBranch: "Branch checked out"
        default: "\(self.title) complete"

        }

    }

}
