import Foundation

struct TextDiffReviewNavigationTarget: Equatable {

    let id = UUID()
    let lineID: Int?
    let side: SourceSide
    let commentID: String

    func anchor(fileID: String, embedsInReviewList: Bool) -> AnyHashable {

        guard let lineID = self.lineID else { return AnyHashable(Self.commentAnchor(fileID: fileID, commentID: self.commentID)) }
        return embedsInReviewList ? AnyHashable("review/\(fileID)/line/\(lineID)") : AnyHashable(lineID)

    }

    static func commentAnchor(fileID: String, commentID: String) -> String {
        "review/\(fileID)/comment/\(commentID)"
    }

}
