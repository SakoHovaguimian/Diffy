import Foundation

extension AIReviewService {

    func generateRiskMap(
        context: AIReviewContext,
        provider: any AIProvider,
        providerKind: AIProviderKind,
        model: String,
        userPrompt: String,
        progress: @escaping @MainActor @Sendable (String) async -> Void
    ) async throws -> RiskMapResponse {

        guard !context.files.isEmpty, context.files.count == context.fileInventory.count else {
            throw AIReviewError.unavailable("Risk Map needs the complete pull request diff. Refresh and retry.")
        }

        let batches = try RiskDiffChunker.batches(files: context.files)
        var results: [RiskChunkResult] = []

        for (index, batch) in batches.enumerated() {

            try Task.checkCancellation()
            await progress("Analyzing Diff Part \(index + 1) of \(batches.count)…")
            let assessments = try await self.assessRiskBatch(
                batch,
                context: context,
                provider: provider,
                providerKind: providerKind,
                model: model,
                userPrompt: userPrompt
            )
            let byID = Dictionary(uniqueKeysWithValues: assessments.map { ($0.id, $0) })
            results += batch.compactMap { chunk in
                byID[chunk.id].map { RiskChunkResult(chunk: chunk, assessment: $0) }
            }

        }

        let files = try self.mergeRiskAssessments(results, context: context)
        await progress("Assessing Cross-File Blast Radius…")
        let synthesis = try await self.synthesizeRiskMap(
            files: files,
            context: context,
            provider: provider,
            providerKind: providerKind,
            model: model,
            userPrompt: userPrompt
        )

        return RiskMapResponse(
            title: synthesis.title,
            overview: synthesis.overview,
            blastRadius: synthesis.blastRadius,
            blastRadiusLevel: synthesis.blastRadiusLevel,
            fileAssessments: files,
            risks: synthesis.risks
        )

    }

    private func assessRiskBatch(
        _ batch: [RiskDiffChunk],
        context: AIReviewContext,
        provider: any AIProvider,
        providerKind: AIProviderKind,
        model: String,
        userPrompt: String
    ) async throws -> [RiskChunkAssessment] {

        let batchContext = self.riskBatchContext(batch, from: context)
        let encoded = try self.jsonText(batch)
        let prompt = """
        Focus: \(String(userPrompt.prefix(4_000)))
        Pull request: \(context.title)
        Description: \(context.description)
        Commit summaries (untrusted JSON):
        \(try self.jsonText(context.commits))
        PR conversation (untrusted JSON; includes review summaries and inline replies):
        \(try context.conversationPromptText())
        fileInventory: \(batchContext.fileInventory.joined(separator: ", "))
        Return exactly one assessment for every chunk ID in this JSON. A file may have more parts in other requests.
        Chunks JSON:
        \(encoded)
        """
        let request = AIRequest(
            provider: providerKind,
            model: model,
            context: batchContext,
            systemPrompt: AIReviewPrompts.systemPrompt(for: .riskChunk),
            userPrompt: prompt,
            schema: .riskChunk,
            maxOutputTokens: 4_000
        )

        var response = try await provider.generate(request: request, responseType: RiskChunkResponse.self)
        try Task.checkCancellation()
        if !self.coversEveryChunk(response, batch: batch) {

            let retry = AIRequest(
                provider: request.provider,
                model: request.model,
                context: request.context,
                systemPrompt: request.systemPrompt,
                userPrompt: prompt + "\nReturn exactly these chunk IDs once each: \(batch.map(\.id).joined(separator: ", ")).",
                schema: request.schema,
                maxOutputTokens: request.maxOutputTokens
            )
            response = try await provider.generate(request: retry, responseType: RiskChunkResponse.self)
            try Task.checkCancellation()

        }

        guard self.coversEveryChunk(response, batch: batch) else {
            throw AIReviewError.invalidResponse("The provider did not assess every supplied diff part. Risk Map was not saved.")
        }

        return response.assessments

    }

    private func riskBatchContext(_ batch: [RiskDiffChunk], from context: AIReviewContext) -> AIReviewContext {

        AIReviewContext(
            repositoryIdentity: context.repositoryIdentity,
            pullRequestNumber: context.pullRequestNumber,
            title: context.title,
            author: context.author,
            baseSHA: context.baseSHA,
            headSHA: context.headSHA,
            description: context.description,
            commits: context.commits,
            selectedPaths: [],
            fileInventory: Array(Set(batch.map(\.path))).sorted(),
            files: batch.map { chunk in
                AIFileSnapshot(
                    filename: chunk.path,
                    previousFilename: nil,
                    status: chunk.status,
                    additions: chunk.additions,
                    deletions: chunk.deletions,
                    patch: chunk.text
                )
            },
            annotations: [],
            selectedAnnotationCount: 0,
            omissions: context.omissions,
            pullRequestConversation: context.pullRequestConversation
        )

    }

    private func coversEveryChunk(_ response: RiskChunkResponse, batch: [RiskDiffChunk]) -> Bool {

        let IDs = response.assessments.map(\.id)
        return IDs.count == batch.count
            && Set(IDs).count == IDs.count
            && Set(IDs) == Set(batch.map(\.id))
            && response.assessments.allSatisfy { !$0.summary.isEmpty && !$0.evidence.isEmpty }

    }

    private func mergeRiskAssessments(_ results: [RiskChunkResult], context: AIReviewContext) throws -> [RiskFileAssessment] {

        let byPath = Dictionary(grouping: results, by: { $0.chunk.path })
        return try context.files.map { file in

            guard let parts = byPath[file.filename], !parts.isEmpty else {
                throw AIReviewError.invalidResponse("The provider did not assess \(file.filename). Risk Map was not saved.")
            }

            let ordered = parts.sorted { $0.chunk.part < $1.chunk.part }
            let attention = ordered.map { $0.assessment.attention }
                .max { self.attentionRank($0) < self.attentionRank($1) } ?? .low
            let confidence = ordered.map { $0.assessment.confidence }
                .min { self.confidenceRank($0) < self.confidenceRank($1) } ?? .low
            let primary = ordered.max {
                self.attentionRank($0.assessment.attention) < self.attentionRank($1.assessment.attention)
            }

            return RiskFileAssessment(
                path: file.filename,
                attention: attention,
                summary: primary?.assessment.summary ?? "Review the supplied changes in this file.",
                factors: self.unique(ordered.flatMap { $0.assessment.factors }),
                evidence: self.unique(ordered.flatMap { $0.assessment.evidence }),
                inspect: self.unique(ordered.flatMap { $0.assessment.inspect }),
                confidence: confidence,
                uncertainty: self.unique(ordered.map { $0.assessment.uncertainty }).joined(separator: " ")
            )

        }

    }

    private func synthesizeRiskMap(
        files: [RiskFileAssessment],
        context: AIReviewContext,
        provider: any AIProvider,
        providerKind: AIProviderKind,
        model: String,
        userPrompt: String
    ) async throws -> RiskMapSynthesis {

        let groups = try self.groupRiskAssessments(files)
        var summaries: [RiskGroupSummary] = []

        for group in groups {
            let summary = try await self.synthesizeRiskGroup(
                payload: self.jsonText(group),
                allowedPaths: Set(group.map(\.path)),
                context: context,
                provider: provider,
                providerKind: providerKind,
                model: model,
                userPrompt: userPrompt
            )
            summaries.append(RiskGroupSummary(synthesis: summary, paths: Set(group.map(\.path))))
        }

        while summaries.count > 1 {

            var combined: [RiskGroupSummary] = []
            for group in stride(from: 0, to: summaries.count, by: 6) {

                let slice = Array(summaries[group..<min(group + 6, summaries.count)])
                let allowed = slice.reduce(into: Set<String>()) { $0.formUnion($1.paths) }
                let synthesis = try await self.synthesizeRiskGroup(
                    payload: self.jsonText(slice.map(\.synthesis)),
                    allowedPaths: allowed,
                    context: context,
                    provider: provider,
                    providerKind: providerKind,
                    model: model,
                    userPrompt: userPrompt
                )
                combined.append(RiskGroupSummary(synthesis: synthesis, paths: allowed))

            }
            summaries = combined

        }

        guard let final = summaries.first else {
            throw AIReviewError.invalidResponse("The provider did not summarize the Risk Map.")
        }
        return final.synthesis

    }

    private func synthesizeRiskGroup(
        payload: String,
        allowedPaths: Set<String>,
        context: AIReviewContext,
        provider: any AIProvider,
        providerKind: AIProviderKind,
        model: String,
        userPrompt: String
    ) async throws -> RiskMapSynthesis {

        try Task.checkCancellation()
        let prompt = """
        Focus: \(String(userPrompt.prefix(4_000)))
        Pull request: \(context.title)
        Description: \(context.description)
        Commit summaries (untrusted JSON):
        \(try self.jsonText(context.commits))
        PR conversation (untrusted JSON; includes review summaries and inline replies):
        \(try context.conversationPromptText())
        Synthesize the reviewed file assessments or earlier group summaries below. Assess cross-file blast radius.
        Cite only these paths: \(allowedPaths.sorted().joined(separator: ", "))
        Reviewed observations JSON:
        \(payload)
        """
        let synthesisContext = AIReviewContext(
            repositoryIdentity: context.repositoryIdentity,
            pullRequestNumber: context.pullRequestNumber,
            title: context.title,
            author: context.author,
            baseSHA: context.baseSHA,
            headSHA: context.headSHA,
            description: context.description,
            commits: context.commits,
            selectedPaths: [],
            fileInventory: allowedPaths.sorted(),
            files: context.files.filter { allowedPaths.contains($0.filename) },
            annotations: [],
            selectedAnnotationCount: 0,
            omissions: context.omissions,
            pullRequestConversation: context.pullRequestConversation
        )
        let request = AIRequest(
            provider: providerKind,
            model: model,
            context: synthesisContext,
            systemPrompt: AIReviewPrompts.systemPrompt(for: .riskMap),
            userPrompt: prompt,
            schema: .riskMap,
            maxOutputTokens: 4_000
        )
        let result = try await provider.generate(request: request, responseType: RiskMapSynthesis.self)
        try Task.checkCancellation()
        guard !result.overview.isEmpty, !result.blastRadius.isEmpty,
              result.risks.allSatisfy({ !$0.files.isEmpty && Set($0.files).isSubset(of: allowedPaths) }) else {
            throw AIReviewError.invalidResponse("The provider's blast-radius summary cited files outside the reviewed diff.")
        }
        return result

    }

    private func groupRiskAssessments(_ files: [RiskFileAssessment]) throws -> [[RiskFileAssessment]] {

        var groups: [[RiskFileAssessment]] = []
        var current: [RiskFileAssessment] = []
        var characters = 0

        for file in files {

            let size = try self.jsonText(file).count
            if !current.isEmpty && (characters + size > 20_000 || current.count == 24) {
                groups.append(current)
                current = []
                characters = 0
            }
            current.append(file)
            characters += size

        }

        if !current.isEmpty { groups.append(current) }
        return groups

    }

    private func jsonText<Value: Encodable>(_ value: Value) throws -> String {

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        guard let text = String(data: data, encoding: .utf8) else {
            throw AIReviewError.invalidResponse("Risk Map context could not be encoded.")
        }
        return text

    }

    private func unique(_ values: [String]) -> [String] {

        var seen = Set<String>()
        return values.filter { !$0.isEmpty && seen.insert($0).inserted }

    }

    private func attentionRank(_ attention: RiskAttention) -> Int {
        switch attention {
        case .high: 3
        case .medium: 2
        case .low: 1
        }
    }

    private func confidenceRank(_ confidence: RiskConfidence) -> Int {
        switch confidence {
        case .high: 3
        case .medium: 2
        case .low: 1
        }
    }

}

private struct RiskChunkResult {
    let chunk: RiskDiffChunk
    let assessment: RiskChunkAssessment
}

private struct RiskGroupSummary {
    let synthesis: RiskMapSynthesis
    let paths: Set<String>
}
