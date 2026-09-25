import SwiftUI

struct TextDiffReviewContext {

    let leftLabel: String
    let rightLabel: String
    let layout: Binding<Bool>
    let visibleDiscussionLineIDs: Set<Int>
    let canComment: Bool
    let comment: (DiffLine, SourceSide) -> Void
    let note: (DiffLine, SourceSide) -> Void
    let hasAnnotation: (DiffLine, SourceSide) -> Bool
    let lineDiscussion: (DiffLine) -> AnyView
    let fileDiscussion: () -> AnyView

}
