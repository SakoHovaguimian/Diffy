import Foundation

/// The outcome of a conditional GitHub request. `value` is nil when the server
/// answered 304 Not Modified and the cached value remains current.
struct GitHubFetchResult<Value: Sendable>: Sendable {
    let value: Value?
    let validators: GitHubResourceValidators
    var rateLimit: GitHubRateLimit?

    var isNotModified: Bool {
        self.value == nil
    }
}
