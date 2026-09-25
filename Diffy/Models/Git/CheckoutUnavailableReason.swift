import Foundation

enum CheckoutUnavailableReason: String, Codable, Hashable, Sendable {
    case missingBookmark
    case staleBookmark
    case folderMissing
    case accessDenied

    var message: String {

        switch self {

        case .missingBookmark:
            "Diffy needs permission to open this folder again. Locate it once to restore access."

        case .staleBookmark:
            "The saved folder permission has expired. Locate the folder to restore access."

        case .folderMissing:
            "The folder was moved, renamed, or deleted. Locate it to reconnect this project."

        case .accessDenied:
            "macOS denied access to this folder. Locate it again to grant access."

        }

    }
}
