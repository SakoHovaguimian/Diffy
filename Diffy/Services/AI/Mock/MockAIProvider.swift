import Foundation

/// Deterministic preview data uses the same Diffy schemas and review service path.
struct MockAIProvider: AIProvider {

    func generate<Response: Decodable & Sendable>(
        request: AIRequest,
        responseType: Response.Type
    ) async throws -> Response {

        let file = request.context.files.first?.filename ?? request.context.fileInventory.first ?? ""
        let value: Any

        switch request.schema {

        case .learningPath:
            value = LearningPathResponse(
                title: "Understand this pull request",
                overview: "A guided route through the change at the recorded revision.",
                steps: [LearningPathStep(
                    id: "start",
                    title: "Read the main change",
                    explanation: "Open the central changed file and follow the new behavior.",
                    whyItMatters: "It establishes the purpose of this PR before reviewing details.",
                    relevantFiles: file.isEmpty ? [] : [file],
                    relevantSymbols: [],
                    suggestedFiles: file.isEmpty ? [] : [file],
                    dependsOn: []
                )]
            )

        case .architectureMap:
            value = ArchitectureMapResponse(
                title: "Architecture Map",
                overview: "Components represented by the supplied pull request context.",
                nodes: [ArchitectureNode(
                    id: "changed-component",
                    label: file.isEmpty ? "Changed component" : file,
                    kind: .other,
                    change: .changed,
                    responsibility: "Owns a part of the changed behavior.",
                    changedFiles: file.isEmpty ? [] : [file],
                    relevantSymbols: [],
                    whyItMatters: "Review its relationships as the change develops."
                )],
                edges: []
            )

        case .riskMap:
            value = RiskMapResponse(
                title: "Risk Map",
                overview: "Areas to inspect in the supplied change.",
                risks: [RiskItem(
                    id: "main-change",
                    title: "Primary behavior",
                    attention: .medium,
                    whyFlagged: "This file carries the main changed behavior.",
                    evidence: ["The supplied patch changes this file."],
                    files: file.isEmpty ? [] : [file],
                    symbols: [],
                    inspect: ["Read the altered control flow and edge cases."],
                    confidence: .low,
                    uncertainty: "Preview data is illustrative."
                )]
            )

        case .question:
            value = AIQuestionResponse(
                answer: "This preview shows where an answer about the PR appears.",
                relevantFiles: file.isEmpty ? [] : [file],
                evidence: [],
                uncertainty: "Preview data is illustrative."
            )

        case .noteFix:
            value = AINoteFixResponse(
                plan: ["Review the selected notes and inspect the affected diff."],
                affectedFiles: file.isEmpty ? [] : [file],
                proposedPatch: "",
                explanation: "No patch is applied in the preview.",
                uncertainty: "Preview data is illustrative."
            )

        }

        guard let typed = value as? Response else {
            throw AIReviewError.invalidResponse("The preview response type did not match its request.")
        }

        return typed

    }
}
