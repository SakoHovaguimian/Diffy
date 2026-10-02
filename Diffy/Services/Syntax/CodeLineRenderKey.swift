import SwiftUI

struct CodeLineRenderKey: Hashable {
    let source: String
    let comparison: String?
    let theme: DiffyTheme
    let whitespace: Bool
    let highlightLevel: String
    let inlineColor: Color
    let emphasis: String?
    let fontName: String
    let fontSize: CGFloat
    let tabWidth: Int
    var lineColumns: Int?
}
