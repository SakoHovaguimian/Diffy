import Foundation

/// A failed Git invocation. `message` is sanitized stderr: no credentials, tokens,
/// authorization headers, or user-info in URLs.
struct GitCommandFailure: Hashable, Sendable {
    let subcommand: String
    let exitStatus: Int32
    let message: String
}
