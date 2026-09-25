import Foundation

struct CachedEntry<Value: Codable & Sendable>: Sendable {
    let value: Value
    let savedAt: Date
}
