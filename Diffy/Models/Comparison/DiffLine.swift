import Foundation

struct DiffLine: Codable, Identifiable, Hashable, Sendable {

    let id: Int
    let oldNumber: Int?
    let newNumber: Int?
    let left: String?
    let right: String?
    let status: FileChangeStatus
    var emphasis: String? = nil

    var isChanged: Bool {
        self.status != .identical
    }

}
