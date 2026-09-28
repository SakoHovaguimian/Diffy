import Foundation

enum AnnotationReviewReason: String, Codable, Sendable {

    case sourceChanged
    case proposedFixApplied

    var message: String {

        switch self {
        case .sourceChanged: "The source changed. Compare the captured code with the current version."
        case .proposedFixApplied: "A proposed fix was applied. Review the local diff before resolving this note."
        }

    }

}
