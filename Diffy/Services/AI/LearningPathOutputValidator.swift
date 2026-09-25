import Foundation

enum LearningPathOutputValidator {

    static func validate(_ response: LearningPathResponse, context: AIReviewContext) throws {

        guard hasText(response.title), hasText(response.overview), !response.steps.isEmpty else {
            throw AIReviewError.invalidResponse("The learning path is missing its introduction or steps. Try generating it again.")
        }

        var priorIDs = Set<String>()
        for step in response.steps {

            guard hasText(step.id), hasText(step.title), hasText(step.explanation),
                  hasText(step.whyItMatters), hasText(step.breakdownDescriptions),
                  !step.relevantFiles.isEmpty, !priorIDs.contains(step.id) else {
                throw AIReviewError.invalidResponse("A learning step is missing its explanation or repeats another step. Try generating it again.")
            }

            guard Set(step.dependsOn).isSubset(of: priorIDs) else {
                throw AIReviewError.invalidResponse("A learning step points to an unknown or later step.")
            }

            guard Set(step.relevantFiles + step.suggestedFiles).isSubset(of: context.analyzedPaths) else {
                throw AIReviewError.invalidResponse("A learning step links to a file outside this review.")
            }

            try validateReferences(in: step)
            try validateExamples(in: step, context: context)
            priorIDs.insert(step.id)

        }

    }

    private static func validateReferences(in step: LearningPathStep) throws {

        let references = step.codeReferences
        guard Set(references.map(\.id)).count == references.count,
              references.allSatisfy({
                  validIdentifier($0.id) && hasText($0.label) && step.relevantFiles.contains($0.filePath)
              }) else {
            throw AIReviewError.invalidResponse("A learning step has an invalid code link. Try generating it again.")
        }

        let markdown = try AttributedString(markdown: step.breakdownDescriptions)
        guard hasText(String(markdown.characters)) else {
            throw AIReviewError.invalidResponse("A learning step has an empty explanation. Try generating it again.")
        }
        for run in markdown.runs {

            if let url = run.link, step.filePath(for: url) == nil {
                throw AIReviewError.invalidResponse("A learning step links to code outside its supplied files.")
            }

        }

    }

    private static func validateExamples(in step: LearningPathStep, context: AIReviewContext) throws {

        guard Set(step.examples.map(\.id)).count == step.examples.count else {
            throw AIReviewError.invalidResponse("A learning step repeats a code example.")
        }

        for example in step.examples {

            guard validIdentifier(example.id), hasText(example.title), hasText(example.code),
                  hasText(example.explanation), step.relevantFiles.contains(example.filePath),
                  let patch = context.files.first(where: { $0.filename == example.filePath })?.patch,
                  !patch.isEmpty else {
                throw AIReviewError.invalidResponse("A code example is missing its explanation or supporting diff.")
            }

            if example.kind == .source, !containsExcerpt(example.code, in: patch) {
                throw AIReviewError.invalidResponse("A code example does not match the supplied diff. Try generating the learning path again.")
            }

        }

    }

    private static func containsExcerpt(_ code: String, in patch: String) -> Bool {

        let excerpt = code.trimmingCharacters(in: .newlines).components(separatedBy: "\n")
        let lines = GitPatchParser.unifiedLines(patch)
        return [SourceSide.left, .right].contains { side in

            let source = lines.compactMap { line -> (number: Int, text: String)? in

                let number = side == .left ? line.oldNumber : line.newNumber
                let text = side == .left ? line.left : line.right
                guard let number, let text else { return nil }
                return (number, text)

            }
            guard source.count >= excerpt.count else { return false }

            return (0...(source.count - excerpt.count)).contains { start in

                let candidate = source[start..<(start + excerpt.count)]
                let isContiguous = candidate.enumerated().allSatisfy { offset, line in
                    line.number == source[start].number + offset
                }
                return isContiguous && candidate.map(\.text) == excerpt

            }

        }

    }

    private static func hasText(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func validIdentifier(_ value: String) -> Bool {
        value.range(of: "^[A-Za-z0-9_-]{1,64}$", options: .regularExpression) != nil
    }

}
