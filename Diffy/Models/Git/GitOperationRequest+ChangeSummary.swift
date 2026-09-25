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

        case .pull: "Pull Complete"
        case .fetch: "Fetch Complete"
        case .startMerge, .continueMerge: "Merge Complete"
        case .startRebase, .continueRebase: "Rebase Complete"
        case .switchBranch: "Branch Checked Out"
        default: "\(self.title) Complete"

        }

    }

}
