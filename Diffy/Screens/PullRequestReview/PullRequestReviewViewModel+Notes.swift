import Foundation

@MainActor
extension PullRequestReviewViewModel {

    var noteProjectID: String { self.projectID ?? self.fallbackNoteProjectID }

    private var fallbackNoteProjectID: String {
        "github/\(self.request.link.host.lowercased())/\(self.request.link.fullName.lowercased())"
    }

    var noteSource: String? {

        guard let summary = self.details?.summary else { return nil }
        return "github/pr/\(self.request.link.host.lowercased())/\(self.request.link.fullName.lowercased())/\(self.request.number)/\(summary.baseSHA)/\(summary.headSHA)"

    }

    func matchingAnnotations(in annotations: [CodeAnnotation]) -> [CodeAnnotation] {

        guard let source = self.noteSource else { return [] }
        return annotations.filter {
            ($0.projectID == self.noteProjectID || $0.projectID == self.fallbackNoteProjectID)
                && $0.source == source
                && !$0.isResolved
        }

    }

    // MARK: - Creating Notes

    func beginNote(line: Int, side: String, snippet: String) {

        guard let file = self.selectedFile,
              let source = self.noteSource,
              let summary = self.details?.summary else { return }

        self.noteDraft = PullRequestNoteDraft(
            filePath: side == "LEFT" ? file.previousFilename ?? file.filename : file.filename,
            line: line,
            side: side == "LEFT" ? .left : .right,
            snippet: snippet,
            language: file.navigationFile.language,
            source: source,
            baseSHA: summary.baseSHA,
            headSHA: summary.headSHA
        )

    }

    func annotation(from draft: PullRequestNoteDraft, comment: String) -> CodeAnnotation {

        CodeAnnotation(
            id: UUID(),
            projectID: self.noteProjectID,
            projectName: self.request.link.fullName,
            comparison: "PR #\(self.request.number) · \(draft.baseSHA) → \(draft.headSHA)",
            filePath: draft.filePath,
            source: draft.source,
            side: draft.side,
            startLine: draft.line,
            endLine: draft.line,
            snippet: draft.snippet,
            language: draft.language,
            createdAt: Date(),
            comment: comment,
            isResolved: false,
            comparisonMode: ComparisonMode.pullRequests.rawValue
        )

    }

}
