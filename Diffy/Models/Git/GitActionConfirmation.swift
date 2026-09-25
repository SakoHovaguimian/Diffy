import Foundation

struct GitActionConfirmation: Identifiable {
    let id = UUID()
    let request: GitOperationRequest
    let projectName: String
    let consequence: String
}
