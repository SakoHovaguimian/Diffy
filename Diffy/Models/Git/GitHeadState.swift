import Foundation

struct GitHeadState: Codable, Hashable, Sendable {
    let branchName: String?
    let commitID: String?

    var isDetached: Bool {
        self.branchName == nil && self.commitID != nil
    }

    var isUnborn: Bool {
        self.commitID == nil
    }

    var shortCommitID: String? {
        self.commitID.map { String($0.prefix(7)) }
    }

    var displayName: String {

        if let branchName = self.branchName {
            return branchName
        }

        if let shortCommitID = self.shortCommitID {
            return "Detached At \(shortCommitID)"
        }

        return "No Commits Yet"

    }
}
