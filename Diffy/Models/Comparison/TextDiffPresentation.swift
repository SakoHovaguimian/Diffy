import Foundation

struct TextDiffPresentation {
    let selection: ComparisonSelection
    let mode: ComparisonMode
    var embedsInReviewList = true

    func lineAnchor(fileID: String, lineID: Int) -> String {
        "review/\(fileID)/line/\(lineID)"
    }
}
