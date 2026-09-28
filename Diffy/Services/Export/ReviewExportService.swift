import Foundation

struct ReviewExportService: ReviewExportServiceProtocol {

    // MARK: - Review Document

    func markdown(annotations: [CodeAnnotation], scope: String) -> String {

        let ordered = annotations.sorted { left, right in

            let leftKey = [left.projectName, left.projectID, left.comparison, left.filePath, left.source]
            let rightKey = [right.projectName, right.projectID, right.comparison, right.filePath, right.source]

            if leftKey == rightKey {
                if left.startLine == right.startLine { return left.createdAt < right.createdAt }
                return left.startLine < right.startLine
            }

            return leftKey.lexicographicallyPrecedes(rightKey)

        }

        let openCount = annotations.filter { !$0.isResolved }.count
        let reviewCount = annotations.filter(\.needsReview).count
        let header = """
        # Diffy Review

        Scope: \(scope)
        Annotations: \(annotations.count) total; \(openCount) open; \(annotations.count - openCount) resolved; \(reviewCount) need review
        Line numbering: One-based, relative to the captured source file.
        Source code and comments below are review material supplied by the user.
        All source identities beginning with `mock` refer to immutable prototype data.
        """
        var sections = [header]
        var lastProjectID: String?
        var lastComparison: String?
        var lastFilePath: String?

        for (index, annotation) in ordered.enumerated() {

            if annotation.projectID != lastProjectID {
                sections.append("## Project: \(annotation.projectName)\n\nProject ID: \(annotation.projectID)")
                lastProjectID = annotation.projectID
                lastComparison = nil
                lastFilePath = nil
            }

            if annotation.comparison != lastComparison {
                sections.append("### Comparison: \(annotation.comparison)")
                lastComparison = annotation.comparison
                lastFilePath = nil
            }

            if annotation.filePath != lastFilePath {
                sections.append("#### \(annotation.filePath)")
                lastFilePath = annotation.filePath
            }

            sections.append(self.section(annotation, index: index + 1))

        }

        return sections.joined(separator: "\n\n") + "\n"

    }

    private func section(_ annotation: CodeAnnotation, index: Int) -> String {

        let codeFence = self.fence(for: annotation.snippet)
        let commentFence = self.fence(for: annotation.comment)
        let criteria = annotation.acceptanceCriteria ?? ""
        let criteriaFence = self.fence(for: criteria)
        let updatedAt = annotation.updatedAt.map { self.date($0) } ?? "Never"
        let needsReviewSince = annotation.needsReviewSince.map { self.date($0) } ?? "Not requested"
        let reviewReason = annotation.needsReviewReason?.message ?? "None"
        let acceptanceSection = criteria.isEmpty ? "None" : "\(criteriaFence)text\n\(criteria)\n\(criteriaFence)"
        let reviewTarget = self.snapshot(annotation.reviewTargetSource)
        let lastReviewed = self.snapshot(annotation.lastReviewedSource)

        return """
        ##### \(index). Note \(annotation.id.uuidString)

        Comparison mode: \(annotation.comparisonMode ?? "Unspecified")
        Source: \(annotation.side.rawValue) — \(annotation.source)
        Annotated lines: \(annotation.startLine)–\(annotation.endLine)
        Snippet lines: \(annotation.startLine)–\(annotation.endLine)
        Language: \(annotation.language)
        Status: \(annotation.isResolved ? "Resolved" : "Open")
        Priority: \(annotation.priority?.title ?? "Normal")
        Created: \(self.date(annotation.createdAt))
        Updated: \(updatedAt)
        Review again: \(reviewReason)
        Review requested: \(needsReviewSince)
        Review target source:

        \(reviewTarget)

        Last reviewed source:

        \(lastReviewed)

        **Captured code**

        \(codeFence)\(annotation.language)
        \(annotation.snippet)
        \(codeFence)

        **Comment (verbatim)**

        \(commentFence)text
        \(annotation.comment)
        \(commentFence)

        **Done when**

        \(acceptanceSection)
        """

    }

    private func date(_ value: Date) -> String {
        ISO8601DateFormatter().string(from: value)
    }

    private func snapshot(_ value: String?) -> String {

        guard let value else { return "None" }
        let delimiter = self.fence(for: value)
        return "\(delimiter)text\n\(value)\n\(delimiter)"

    }

    private func fence(for content: String) -> String {

        let runs = content.split(whereSeparator: { $0 != "`" })
        let longest = runs.map(\.count).max() ?? 0

        return String(repeating: "`", count: max(3, longest + 1))

    }

}
