import Foundation

struct LearningPathStep: Codable, Hashable, Identifiable, Sendable {

    let id: String
    let title: String
    let explanation: String
    let whyItMatters: String
    let relevantFiles: [String]
    let relevantSymbols: [String]
    let suggestedFiles: [String]
    let dependsOn: [String]
    let breakdownDescriptions: String
    let codeReferences: [LearningPathCodeReference]
    let examples: [LearningPathExample]

    init(
        id: String,
        title: String,
        explanation: String,
        whyItMatters: String,
        relevantFiles: [String],
        relevantSymbols: [String],
        suggestedFiles: [String],
        dependsOn: [String],
        breakdownDescriptions: String = "",
        codeReferences: [LearningPathCodeReference] = [],
        examples: [LearningPathExample] = []
    ) {

        self.id = id
        self.title = title
        self.explanation = explanation
        self.whyItMatters = whyItMatters
        self.relevantFiles = relevantFiles
        self.relevantSymbols = relevantSymbols
        self.suggestedFiles = suggestedFiles
        self.dependsOn = dependsOn
        self.breakdownDescriptions = breakdownDescriptions
        self.codeReferences = codeReferences
        self.examples = examples

    }

    // Older saved generations remain readable without rewriting their records.
    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.whyItMatters = try container.decode(String.self, forKey: .whyItMatters)
        self.relevantFiles = try container.decode([String].self, forKey: .relevantFiles)
        self.relevantSymbols = try container.decode([String].self, forKey: .relevantSymbols)
        self.suggestedFiles = try container.decode([String].self, forKey: .suggestedFiles)
        self.dependsOn = try container.decode([String].self, forKey: .dependsOn)
        self.breakdownDescriptions = try container.decodeIfPresent(String.self, forKey: .breakdownDescriptions) ?? ""
        self.codeReferences = try container.decodeIfPresent([LearningPathCodeReference].self, forKey: .codeReferences) ?? []
        self.examples = try container.decodeIfPresent([LearningPathExample].self, forKey: .examples) ?? []

    }

    private enum CodingKeys: String, CodingKey {
        case id, title, explanation, whyItMatters, relevantFiles, relevantSymbols, suggestedFiles, dependsOn
        case breakdownDescriptions = "breakdown_descriptions"
        case codeReferences, examples
    }

}
