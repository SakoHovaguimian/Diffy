import Foundation

enum MockLearningPathBuilder {

    static func response(context: AIReviewContext) -> LearningPathResponse {

        let file = context.files.first { context.patchPaths.contains($0.filename) } ?? context.files.first
        let path = file?.filename ?? context.fileInventory.first ?? ""
        let files = path.isEmpty ? [] : [path]
        let references = path.isEmpty ? [] : [LearningPathCodeReference(id: "change", label: "Changed file", filePath: path)]
        let examples = sourceExample(file: file)
        let recordExamples = recordExample(file: file)

        return LearningPathResponse(
            title: "Follow The Change, One Step At A Time",
            overview: "A preview of your guided review. Explore each step, read an example, and jump straight to the code.",
            steps: [
                LearningPathStep(
                    id: "behavior",
                    title: "Start With What Changed",
                    explanation: "See the changed lines in context before following the rest of the code.",
                    whyItMatters: "Reading the nearby code helps explain what the change will do.",
                    relevantFiles: files,
                    relevantSymbols: [],
                    suggestedFiles: files,
                    dependsOn: [],
                    breakdownDescriptions: """
                    ### Read the change in context
                    A diff shows **what changed**. The surrounding code helps explain why those lines matter.
                    Open the [changed file](diffy://learning-code/change) to see the full supplied patch.

                    ### Follow one case
                    - Start with a value entering the changed code.
                    - Follow the branch or function that uses it.
                    - Look at the value or action it produces.

                    \(examples.isEmpty ? "No text patch was supplied for this file, so this preview has no code example." : "The excerpt below is copied from the supplied patch. A generated review explains its specific behavior here.")
                    """,
                    codeReferences: references,
                    examples: examples
                ),
                LearningPathStep(
                    id: "context",
                    title: "Keep The Code In Context",
                    explanation: "Connect the explanation to the exact file and version being reviewed.",
                    whyItMatters: "A saved review should always point back to the code it explained.",
                    relevantFiles: files,
                    relevantSymbols: [],
                    suggestedFiles: files,
                    dependsOn: ["behavior"],
                    breakdownDescriptions: """
                    ### What the review remembers
                    Each explanation is tied to a file and the version of the pull request that was analyzed.
                    \(recordExamples.isEmpty ? "No text patch was supplied, so this step has no code example." : "The example below shows a **simplified record**, not a model from the repository.")

                    ### When the code changes
                    Opening the [changed file](diffy://learning-code/change) from an older review shows its saved diff.
                    That keeps the explanation and the code together, even after another commit.
                    """,
                    codeReferences: references,
                    examples: recordExamples
                )
            ]
        )

    }

    private static func sourceExample(file: AIFileSnapshot?) -> [LearningPathExample] {

        guard let file, let patch = file.patch, !patch.isEmpty else { return [] }
        let lines = GitPatchParser.unifiedLines(patch).filter { $0.newNumber != nil }
        guard let start = lines.firstIndex(where: { $0.status == .added }),
              let startNumber = lines[start].newNumber else { return [] }
        let excerpt = lines[start...].prefix(10).enumerated()
            .prefix(while: { $0.element.newNumber == startNumber + $0.offset })
            .compactMap { $0.element.right }.joined(separator: "\n")
        guard !excerpt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        return [LearningPathExample(
            id: "source",
            title: "A Closer Look At The Change",
            kind: .source,
            language: (file.filename as NSString).pathExtension,
            code: excerpt,
            explanation: "These lines come from the supplied diff. Click the code to open its file.",
            filePath: file.filename
        )]

    }

    private static func recordExample(file: AIFileSnapshot?) -> [LearningPathExample] {

        guard let file, let patch = file.patch, !patch.isEmpty,
              let data = try? JSONSerialization.data(
                  withJSONObject: ["file": file.filename, "added": file.additions, "removed": file.deletions],
                  options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
              ),
              let code = String(data: data, encoding: .utf8) else { return [] }

        return [LearningPathExample(
            id: "record",
            title: "An Example Review Record",
            kind: .illustrative,
            language: "json",
            code: code,
            explanation: "The file identifies the change; added and removed count the lines in its diff.",
            filePath: file.filename
        )]

    }

}
