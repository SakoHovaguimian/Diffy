import Foundation

enum AIOutputValidator {

    static func validate(_ output: AIReviewOutput, context: AIReviewContext) throws {

        switch output {

        case .learningPath(let response): try self.validateLearningPath(response, context: context)
        case .architectureMap(let response): try self.validateArchitectureMap(response, context: context)
        case .riskMap(let response): try self.validateRiskMap(response, context: context)

        }

    }

    static func validate(_ response: AIQuestionResponse, context: AIReviewContext) throws {

        guard !response.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIReviewError.invalidResponse("The answer was empty.")
        }

        try self.validatePaths(response.relevantFiles, context: context)

    }

    static func validate(_ response: AINoteFixResponse, context: AIReviewContext) throws {

        guard !response.plan.isEmpty else {
            throw AIReviewError.invalidResponse("The proposed plan was empty.")
        }

        try self.validatePaths(response.affectedFiles, context: context)

        if !response.proposedPatch.isEmpty {

            guard !response.affectedFiles.isEmpty,
                  response.affectedFiles.allSatisfy(context.patchPaths.contains) else {
                throw AIReviewError.invalidResponse("A proposed patch referenced files without supplied patches.")
            }

        }

    }

    private static func validateLearningPath(_ response: LearningPathResponse, context: AIReviewContext) throws {

        guard !response.steps.isEmpty else {
            throw AIReviewError.invalidResponse("The learning path had no steps.")
        }

        var priorIDs = Set<String>()

        for step in response.steps {

            guard !step.id.isEmpty, !step.title.isEmpty,
                  !step.explanation.isEmpty, !step.whyItMatters.isEmpty,
                  !step.relevantFiles.isEmpty, !priorIDs.contains(step.id) else {
                throw AIReviewError.invalidResponse("The learning path contained a duplicate or empty step.")
            }

            guard Set(step.dependsOn).isSubset(of: priorIDs) else {
                throw AIReviewError.invalidResponse("A learning step depends on an unknown or later step.")
            }

            try self.validatePaths(step.relevantFiles + step.suggestedFiles, context: context)
            priorIDs.insert(step.id)

        }

    }

    private static func validateArchitectureMap(_ response: ArchitectureMapResponse, context: AIReviewContext) throws {

        guard !response.nodes.isEmpty else {
            throw AIReviewError.invalidResponse("The architecture map had no nodes.")
        }

        let nodeIDs = response.nodes.map(\.id)
        let edgeIDs = response.edges.map(\.id)

        guard Set(nodeIDs).count == nodeIDs.count, !nodeIDs.contains("") else {
            throw AIReviewError.invalidResponse("The architecture map contained duplicate nodes.")
        }

        guard Set(edgeIDs).count == edgeIDs.count, !edgeIDs.contains("") else {
            throw AIReviewError.invalidResponse("The architecture map contained duplicate connections.")
        }

        for node in response.nodes {

            guard !node.label.isEmpty, !node.responsibility.isEmpty, !node.whyItMatters.isEmpty else {
                throw AIReviewError.invalidResponse("An architecture component was incomplete.")
            }

            try self.validatePaths(node.changedFiles, context: context)

            guard node.changedFiles.allSatisfy(context.patchPaths.contains) else {
                throw AIReviewError.invalidResponse("A changed component referenced a patch that was not supplied.")
            }
        }

        for edge in response.edges {

            guard nodeIDs.contains(edge.sourceID), nodeIDs.contains(edge.targetID) else {
                throw AIReviewError.invalidResponse("An architecture connection has an unknown endpoint.")
            }

        }

    }

    private static func validateRiskMap(_ response: RiskMapResponse, context: AIReviewContext) throws {

        let IDs = response.risks.map(\.id)

        guard !response.overview.isEmpty else {
            throw AIReviewError.invalidResponse("The risk map lacked a review summary.")
        }

        guard Set(IDs).count == IDs.count, !IDs.contains("") else {
            throw AIReviewError.invalidResponse("The risk map contained duplicate areas.")
        }

        for risk in response.risks {

            guard !risk.whyFlagged.isEmpty, !risk.evidence.isEmpty,
                  !risk.files.isEmpty, !risk.inspect.isEmpty else {
                throw AIReviewError.invalidResponse("A review area lacked evidence or a file to inspect.")
            }

            try self.validatePaths(risk.files, context: context)

            guard risk.files.allSatisfy(context.patchPaths.contains) else {
                throw AIReviewError.invalidResponse("A risk cited a patch that was not supplied.")
            }

        }

    }

    private static func validatePaths(_ paths: [String], context: AIReviewContext) throws {

        guard paths.allSatisfy(context.analyzedPaths.contains) else {
            throw AIReviewError.invalidResponse("A file reference was not in the supplied PR context.")
        }

    }
}
