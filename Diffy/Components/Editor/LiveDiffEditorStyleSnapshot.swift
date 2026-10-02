import SwiftUI

struct LiveDiffEditorStyleSnapshot: Equatable {
    let text: String
    let lineStatuses: [FileChangeStatus]
    let lineComparisons: [String?]
    let preferences: EditorPreferences
    let theme: DiffyTheme
    let contentSize: DiffyContentSize
}
