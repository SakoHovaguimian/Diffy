import Foundation

/// Encoded image data for each side. A missing side means the file was added or removed.
struct ImageComparisonSources: Hashable, Sendable {
    let original: Data?
    let updated: Data?
}
