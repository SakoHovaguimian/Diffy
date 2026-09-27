import Foundation

enum WorkspaceCustomIcon: Codable, Hashable, Sendable {

    case emoji(String)
    case image(Data)
    case filledImage(Data)

    var imageLayout: WorkspaceIconImageLayout? {

        switch self {

        case .emoji: nil
        case .image: .fit
        case .filledImage: .fill

        }

    }

    func withImageLayout(_ layout: WorkspaceIconImageLayout) -> WorkspaceCustomIcon {

        switch self {

        case .emoji:
            return self

        case let .image(data), let .filledImage(data):
            return layout == .fill ? .filledImage(data) : .image(data)

        }

    }

}
