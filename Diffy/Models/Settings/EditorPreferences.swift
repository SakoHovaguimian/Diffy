import Foundation

struct EditorPreferences: Codable, Equatable {

    var fontName: String = "SF Mono"
    var fontSize: Double = 12
    var lineHeight: Double = 25
    var tabWidth: Int = 4
    var wrapLines: Bool = true
    var showLineNumbers: Bool = true
    var showWhitespace: Bool = false
    var ligatures: Bool = true
    var unified: Bool = false
    var collapseUnchanged: Bool = false
    var ignoreWhitespace: Bool = false
    var ignoreComments: Bool = false
    var highlightLevel: String = "Word"
    var contextLines: Int = 3

}
