import Foundation

enum MockPreviewFixtures {

    static var project: RepositoryProject {
        MockWorkspaceFixtures.projects[0]
    }

    static var textFile: DiffFile {
        self.project.files.first { $0.kind == .text && !$0.lines.isEmpty } ?? self.project.files[0]
    }

    static var addedTextFile: DiffFile {
        self.project.files.first { $0.kind == .text && $0.hasNoOriginalSource } ?? self.textFile
    }

    static var imageFile: DiffFile {
        self.project.files.first { $0.kind == .image } ?? self.project.files[0]
    }

    static var selectedLine: DiffLine {
        self.textFile.lines.first { $0.isChanged && $0.newNumber != nil } ?? self.textFile.lines[0]
    }

    static var annotationDraft: AnnotationDraft {

        AnnotationDraft(
            file: self.textFile,
            side: .right,
            startLine: self.selectedLine.newNumber ?? 1,
            endLine: self.selectedLine.newNumber ?? 1,
            snippet: self.selectedLine.right ?? "",
            source: "mock/HEAD → Working tree/right/v1"
        )

    }

    static var annotation: CodeAnnotation {

        CodeAnnotation(
            id: UUID(uuidString: "EC0B151D-043E-4423-83D9-4B4C00C11518") ?? UUID(),
            projectID: self.project.id,
            projectName: self.project.displayName,
            comparison: "HEAD → Working tree",
            filePath: self.textFile.path,
            source: "mock/HEAD → Working tree/right/v1",
            side: .right,
            startLine: self.selectedLine.newNumber ?? 1,
            endLine: self.selectedLine.newNumber ?? 1,
            snippet: self.selectedLine.right ?? "",
            language: self.textFile.language,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            comment: "Check the contrast of this state before shipping.",
            isResolved: false,
            comparisonMode: ComparisonMode.workingTree.rawValue
        )

    }

    static func comparisonReview(startsExpanded: Bool) -> ComparisonReviewRequest {

        ComparisonReviewRequest(
            repository: GitRepositoryReference(
                projectID: self.project.id,
                checkout: LocalCheckoutReference(bookmarkData: nil, lastKnownPath: "/preview/\(self.project.name)")
            ),
            selection: ComparisonSelection(left: .revision("main"), right: .revision("feature/refine-the-details")),
            title: startsExpanded ? "Compare branches" : "Pull complete",
            detail: startsExpanded ? "main → feature/refine-the-details" : "Updated your branch · b4f1d08 → a7e2c91",
            startsExpanded: startsExpanded,
            mode: .branches
        )

    }

    static var region: DiffRegion {

        let allLines = self.textFile.lines
        let start = allLines.firstIndex(where: \.isChanged) ?? 0
        let status = allLines[start].status
        let lines = Array(allLines.dropFirst(start).prefix { $0.status == status })

        return DiffRegion(
            id: lines.first?.id ?? 0,
            lines: lines,
            isChanged: true
        )

    }

}
