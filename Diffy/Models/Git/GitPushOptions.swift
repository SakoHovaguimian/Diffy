import Foundation

struct GitPushOptions: Hashable, Sendable {
    var remote: String?
    var branch: String?
    var setsUpstream: Bool = false

    /// Uses `--force-with-lease`. Unrestricted `--force` is never offered.
    var forceWithLease: Bool = false
}
