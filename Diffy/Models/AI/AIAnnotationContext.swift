import Foundation

struct AIAnnotationContext: Codable, Hashable, Sendable {
    let filePath: String
    let side: String
    let startLine: Int
    let endLine: Int
    let snippet: String
    let language: String
    let comment: String
    let priority: String?
    let acceptanceCriteria: String?

    init(
        filePath: String,
        side: String,
        startLine: Int,
        endLine: Int,
        snippet: String,
        language: String,
        comment: String,
        priority: String? = nil,
        acceptanceCriteria: String? = nil
    ) {

        self.filePath = filePath
        self.side = side
        self.startLine = startLine
        self.endLine = endLine
        self.snippet = snippet
        self.language = language
        self.comment = comment
        self.priority = priority
        self.acceptanceCriteria = acceptanceCriteria

    }

    init(annotation: CodeAnnotation) {

        self.filePath = annotation.filePath
        self.side = annotation.side.rawValue
        self.startLine = annotation.startLine
        self.endLine = annotation.endLine
        self.snippet = annotation.snippet
        self.language = annotation.language
        self.comment = annotation.comment
        self.priority = annotation.priority?.title
        self.acceptanceCriteria = annotation.acceptanceCriteria

    }

    func boundedForPrompt() -> AIAnnotationContext {

        AIAnnotationContext(
            filePath: self.filePath,
            side: self.side,
            startLine: self.startLine,
            endLine: self.endLine,
            snippet: String(self.snippet.prefix(1_500)),
            language: self.language,
            comment: String(self.comment.prefix(2_000)),
            priority: self.priority,
            acceptanceCriteria: self.acceptanceCriteria.map { String($0.prefix(1_000)) }
        )

    }
}
