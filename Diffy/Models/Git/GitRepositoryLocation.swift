import Foundation

/// The resolved on-disk layout of a repository. A linked worktree has a Git directory
/// that differs from the common directory where shared refs and objects live.
struct GitRepositoryLocation: Codable, Hashable, Sendable {
    let rootPath: String
    let gitDirectoryPath: String
    let commonDirectoryPath: String
    var renewedCheckout: LocalCheckoutReference?

    var isLinkedWorktree: Bool {
        self.gitDirectoryPath != self.commonDirectoryPath
    }
}
