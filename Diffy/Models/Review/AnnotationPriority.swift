import Foundation

enum AnnotationPriority: String, Codable, CaseIterable, Identifiable, Sendable {

    case normal
    case important
    case urgent

    var id: String { self.rawValue }

    var title: String {

        switch self {
        case .normal: "Normal"
        case .important: "Important"
        case .urgent: "Urgent"
        }

    }

}
