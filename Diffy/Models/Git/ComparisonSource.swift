import Foundation

/// One side of a comparison. Selecting a revision never implies checking it out.
enum ComparisonSource: Codable, Hashable, Sendable {
    case workingTree
    case index
    case head
    case revision(String)
    case parent(of: String)

    var label: String {

        switch self {

        case .workingTree: "Working tree"
        case .index: "Index"
        case .head: "HEAD"
        case let .revision(revision): Self.abbreviated(revision)
        case let .parent(commit): "\(Self.abbreviated(commit))^"

        }

    }

    private static func abbreviated(_ revision: String) -> String {

        let isObjectID = revision.count >= 40 && revision.allSatisfy(\.isHexDigit)
        return isObjectID ? String(revision.prefix(7)) : revision

    }
}
