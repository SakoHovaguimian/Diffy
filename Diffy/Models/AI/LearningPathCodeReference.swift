import Foundation

struct LearningPathCodeReference: Codable, Hashable, Identifiable, Sendable {

    let id: String
    let label: String
    let filePath: String

    var url: URL? {
        URL(string: "diffy://learning-code/\(self.id)")
    }

}
