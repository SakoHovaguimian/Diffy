import Foundation

struct TextDiffPresentation {
    let selection: ComparisonSelection
    let mode: ComparisonMode

    func lineAnchor(fileID: String, lineID: Int) -> String {
        "review/\(fileID)/line/\(lineID)"
    }
}
