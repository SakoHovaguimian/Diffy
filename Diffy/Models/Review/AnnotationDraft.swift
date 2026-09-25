import Foundation

struct AnnotationDraft: Identifiable {
    let id = UUID()
    let file: DiffFile
    let side: SourceSide
    let startLine: Int
    let endLine: Int
    let snippet: String
    let source: String
}
