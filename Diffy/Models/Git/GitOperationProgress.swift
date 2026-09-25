import Foundation

struct GitOperationProgress: Hashable, Sendable {
    let phase: String
    var fractionCompleted: Double?
}
