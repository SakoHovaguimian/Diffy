import Foundation

struct AIModelCatalog: Sendable {
    let modelIDs: [String]
    let recommendedModelID: String?
    let sourceDescription: String
    let notice: String?
}
