import Foundation

struct DiffLineClipboardContent {

    let filePath: String
    let lineNumber: Int
    let side: SourceSide
    let source: String
    let language: String

    var markdown: String {

        let backtickRuns = self.source.split(whereSeparator: { $0 != "`" })
        let longestRun = backtickRuns.map(\.count).max() ?? 0
        let fence = String(repeating: "`", count: max(3, longestRun + 1))

        return """
        # Diffy Code Line

        File: \(self.filePath)
        Line: \(self.lineNumber) (one-based)
        Side: \(self.side.rawValue)

        ## Contents

        \(fence)\(self.language)
        \(self.source)
        \(fence)
        """

    }

}
