import Foundation

struct GitCommandOutput: Sendable {
    let status: Int32
    let data: Data
    let error: String

    var text: String {
        String(decoding: self.data, as: UTF8.self)
    }

    var trimmed: String {
        self.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
