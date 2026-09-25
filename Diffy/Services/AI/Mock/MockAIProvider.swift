import Foundation

/// Deterministic preview data uses the same Diffy schemas and review service path.
struct MockAIProvider: AIProvider {

    func generate<Response: Decodable & Sendable>(
        request: AIRequest,
        responseType: Response.Type
    ) async throws -> Response {

        let file = request.context.files.first?.filename ?? request.context.fileInventory.first ?? ""
        let patchFile = request.context.files.first {
            request.context.patchPaths.contains($0.filename)
        }?.filename
        let value: Any

        switch request.schema {

        case .learningPath:
            value = MockLearningPathBuilder.response(context: request.context)

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
                    changedFiles: patchFile.map { [$0] } ?? [],
                    relevantSymbols: [],
                    whyItMatters: "Review its relationships as the change develops."
                )],
                edges: []
            )

        case .riskChunk:
            value = RiskChunkResponse(
                assessments: request.context.files.enumerated().map { index, snapshot in
                    RiskChunkAssessment(
                        id: "chunk-\(index)",
                        attention: .medium,
                        summary: "Review the changed behavior in \(snapshot.filename).",
                        factors: ["Changed behavior"],
                        evidence: ["The supplied diff part includes this file."],
                        inspect: ["Read the changed lines and their callers."],
                        confidence: .low,
                        uncertainty: "Preview data is illustrative."
                    )
                }
            )

        case .riskMap:

            let risks: [RiskItem]
            if let patchFile {
                risks = [RiskItem(
                    id: "main-change",
                    title: "Primary behavior",
                    attention: .medium,
                    whyFlagged: "This file carries the main changed behavior.",
                    evidence: ["The supplied patch changes this file."],
                    files: [patchFile],
                    symbols: [],
                    inspect: ["Read the altered control flow and edge cases."],
                    confidence: .low,
                    uncertainty: "Preview data is illustrative."
                )]
            } else {
                risks = []
            }

            value = RiskMapSynthesis(
                title: "Risk Map",
                overview: "Areas to inspect in the supplied change.",
                blastRadius: "Review the affected paths and their callers together.",
                blastRadiusLevel: .medium,
                risks: risks
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
