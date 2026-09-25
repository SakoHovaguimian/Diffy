import Foundation

enum AIModelIdentifier {

    static func isValid(_ identifier: String) -> Bool {

        guard identifier.count <= 150 else { return false }

        guard let match = identifier.range(
            of: "^[A-Za-z0-9][A-Za-z0-9._:-]{0,149}(\\[1m\\])?$",
            options: .regularExpression
        ) else {
            return false
        }

        return match == identifier.startIndex..<identifier.endIndex

    }
}
