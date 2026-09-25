import Foundation

enum AIOutputValidator {

    static func validate(_ output: AIReviewOutput, context: AIReviewContext) throws {

        switch output {

        case .learningPath(let response): try LearningPathOutputValidator.validate(response, context: context)
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

            if let path = node.changedFiles.first(where: { !context.patchPaths.contains($0) }) {
                throw AIReviewError.invalidResponse("No text patch was supplied for \(path). Review that file directly or choose files with available patches.")
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

        if let assessments = response.fileAssessments {

            let paths = assessments.map(\.path)
            guard paths.count == context.fileInventory.count,
                  Set(paths) == context.analyzedPaths,
                  assessments.allSatisfy({ !$0.summary.isEmpty && !$0.evidence.isEmpty }) else {
                throw AIReviewError.invalidResponse("The Risk Map did not assess every changed file.")
            }

        }

        if let blastRadius = response.blastRadius, blastRadius.isEmpty {
            throw AIReviewError.invalidResponse("The Risk Map did not explain its blast radius.")
        }

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

            if let path = risk.files.first(where: { !context.patchPaths.contains($0) }) {
                throw AIReviewError.invalidResponse("No text patch was supplied for \(path). Review that file directly or choose files with available patches.")
            }

        }

    }

    private static func validatePaths(_ paths: [String], context: AIReviewContext) throws {

        guard paths.allSatisfy(context.analyzedPaths.contains) else {
            throw AIReviewError.invalidResponse("A file reference was not in the supplied PR context.")
        }

    }
}
