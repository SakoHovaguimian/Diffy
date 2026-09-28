import Foundation

enum AnnotationSourceMatcher {

    static func currentSnippet(for annotation: CodeAnnotation, in file: DiffFile) -> String? {

        guard file.isContentLoaded else { return nil }
        guard file.path == annotation.filePath || file.originalPath == annotation.filePath else { return nil }
        guard annotation.side == .left || annotation.side == .right else { return nil }

        let sourceLines = file.lines.filter { line in

            let number = annotation.side == .left ? line.oldNumber : line.newNumber
            guard let number else { return false }
            return (annotation.startLine...annotation.endLine).contains(number)

        }
        return sourceLines.compactMap {
            annotation.side == .left ? $0.left : $0.right
        }
        .joined(separator: "\n")

    }

}
