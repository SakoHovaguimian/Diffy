import Foundation

struct GitHubRateLimit: Hashable, Sendable {
    var remaining: Int?
    var resetsAt: Date?
    var retryAfter: TimeInterval?

    var isExhausted: Bool {
        self.remaining == 0 || self.retryAfter != nil
    }
}
