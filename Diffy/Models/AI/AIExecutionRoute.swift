import Foundation

enum AIExecutionRoute: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case providerAPI
    case installedCLI

    var id: String { self.rawValue }

    var title: String {

        switch self {

        case .providerAPI: "API key"
        case .installedCLI: "Installed command line tool"

        }

    }
}
