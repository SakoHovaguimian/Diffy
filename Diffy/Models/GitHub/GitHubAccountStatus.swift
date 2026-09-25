import Foundation

enum GitHubAccountStatus: String, Codable, Hashable, Sendable {
    case connected
    case reauthorizationRequired

    var title: String {

        switch self {

        case .connected: "Connected"
        case .reauthorizationRequired: "Reconnect Required"

        }

    }
}
