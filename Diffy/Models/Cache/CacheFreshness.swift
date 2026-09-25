import Foundation

/// How current the displayed data is. Cached data is always shown immediately and
/// marked, then replaced only after a successful refresh.
enum CacheFreshness: Hashable, Sendable {
    case none
    case live(refreshedAt: Date)
    case cached(savedAt: Date)
    case stale(savedAt: Date)
    case offline(savedAt: Date?)

    var isCurrent: Bool {

        if case .live = self {
            return true
        }

        return false

    }

    var savedAt: Date? {

        switch self {

        case .none: nil
        case let .live(date), let .cached(date), let .stale(date): date
        case let .offline(date): date

        }

    }
}
