import Foundation

/// Identifies a project's checkout for a Git service call.
struct GitRepositoryReference: Hashable, Sendable {
    let projectID: String
    let checkout: LocalCheckoutReference
}
