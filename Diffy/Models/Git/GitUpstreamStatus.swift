import Foundation

struct GitUpstreamStatus: Codable, Hashable, Sendable {
    let name: String
    let remoteName: String?
    let ahead: Int
    let behind: Int
    var isGone: Bool = false

    var isInSync: Bool {
        self.ahead == 0 && self.behind == 0 && !self.isGone
    }

    var hasDiverged: Bool {
        self.ahead > 0 && self.behind > 0
    }
}
