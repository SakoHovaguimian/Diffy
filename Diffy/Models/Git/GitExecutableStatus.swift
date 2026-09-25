import Foundation

struct GitExecutableStatus: Hashable, Sendable {
    let path: String?
    let version: String?
    let problem: String?
    let isCustomPath: Bool

    var isAvailable: Bool {
        self.path != nil && self.problem == nil
    }
}
