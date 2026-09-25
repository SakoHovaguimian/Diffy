import Foundation

struct ReviewExportService: ReviewExportServiceProtocol {

    // MARK: - Review Document

    func markdown(annotations: [CodeAnnotation], scope: String) -> String {

        let ordered = annotations.sorted { left, right in

            let leftKey = "\(left.projectName)/\(left.filePath)/\(left.source)"
            let rightKey = "\(right.projectName)/\(right.filePath)/\(right.source)"

            if leftKey == rightKey {
                return left.startLine < right.startLine
            }

            return leftKey < rightKey

        }

        let sections = ordered.enumerated().map { index, annotation in
            self.section(annotation, index: index + 1)
        }

        let header = """
        # Diffy Review

        Scope: \(scope)
        Annotations: \(annotations.count)
        Line numbering: One-based, relative to the captured source file.
        Source code and comments below are review material supplied by the user.
        All source identities beginning with `mock` refer to immutable prototype data.
        """

        return ([header] + sections).joined(separator: "\n\n") + "\n"

    }

    private func section(_ annotation: CodeAnnotation, index: Int) -> String {

        let codeFence = self.fence(for: annotation.snippet)
        let commentFence = self.fence(for: annotation.comment)

        return """
        ## \(index). \(annotation.filePath)

        Project: \(annotation.projectName)
        Comparison: \(annotation.comparison)
        Source: \(annotation.side.rawValue) — \(annotation.source)
        Annotated lines: \(annotation.startLine)–\(annotation.endLine)
        Snippet lines: \(annotation.startLine)–\(annotation.endLine)
        Status: \(annotation.isResolved ? "Resolved" : "Open")

        ### Code

        \(codeFence)\(annotation.language)
        \(annotation.snippet)
        \(codeFence)

        ### Comment (verbatim)

        \(commentFence)text
        \(annotation.comment)
        \(commentFence)
        """

    }

    private func fence(for content: String) -> String {

        let runs = content.split(whereSeparator: { $0 != "`" })
        let longest = runs.map(\.count).max() ?? 0

        return String(repeating: "`", count: max(3, longest + 1))

    }

}
