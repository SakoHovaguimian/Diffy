import Foundation

/// The environment Diffy is assembled for. Targets choose it with a Swift compilation
/// condition: Diffy Live defines `DIFFY_LIVE` and Diffy Mock defines `DIFFY_MOCK`.
/// Previews always use `.preview`, which is mock-backed and in memory.
enum AppRuntime: String, Sendable {

    case live
    case mock
    case preview

    static var current: AppRuntime {

        #if DIFFY_LIVE
        return .live
        #else
        return .mock
        #endif

    }

    var badgeTitle: String? {

        switch self {

        case .live: nil
        case .mock: "MOCK"
        case .preview: "PREVIEW"

        }

    }

    var windowTitle: String {
        self == .live ? "Diffy" : "Diffy Mock"
    }

    var isLive: Bool {
        self == .live
    }

}
