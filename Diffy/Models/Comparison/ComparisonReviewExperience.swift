import Foundation

enum ComparisonReviewExperience: String, CaseIterable, Identifiable {
    case editor = "File Navigator"
    case review = "Review Files"

    var id: String { self.rawValue }
}
