import Foundation

/// One provider-independent shape per Diffy presentation. Keep every field required
/// so strict output mode has the same contract across providers.
enum AIResponseSchema: String, Sendable {
    case learningPath
    case architectureMap
    case riskChunk
    case riskMap
    case question
    case noteFix

    var name: String { "diffy_\(self.rawValue)" }

    var jsonObject: [String: Any] {

        switch self {

        case .learningPath:
            Self.object([
                "title": Self.string,
                "overview": Self.string,
                "steps": Self.array(Self.object([
                    "id": Self.string,
                    "title": Self.string,
                    "explanation": Self.string,
                    "whyItMatters": Self.string,
                    "relevantFiles": Self.array(Self.string),
                    "relevantSymbols": Self.array(Self.string),
                    "suggestedFiles": Self.array(Self.string),
                    "dependsOn": Self.array(Self.string),
                    "breakdown_descriptions": Self.string,
                    "codeReferences": Self.array(Self.object([
                        "id": Self.string,
                        "label": Self.string,
                        "filePath": Self.string
                    ])),
                    "examples": Self.array(Self.object([
                        "id": Self.string,
                        "title": Self.string,
                        "kind": Self.enumeration(["source", "illustrative"]),
                        "language": Self.string,
                        "code": Self.string,
                        "explanation": Self.string,
                        "filePath": Self.string
                    ]))
                ]))
            ])

        case .architectureMap:
            Self.object([
                "title": Self.string,
                "overview": Self.string,
                "nodes": Self.array(Self.object([
                    "id": Self.string,
                    "label": Self.string,
                    "kind": Self.enumeration(["view", "viewModel", "service", "api", "model", "persistence", "other"]),
                    "change": Self.enumeration(["changed", "existingAffected", "unchangedDependency", "newDependency"]),
                    "responsibility": Self.string,
                    "changedFiles": Self.array(Self.string),
                    "relevantSymbols": Self.array(Self.string),
                    "whyItMatters": Self.string
                ])),
                "edges": Self.array(Self.object([
                    "id": Self.string,
                    "sourceID": Self.string,
                    "targetID": Self.string,
                    "kind": Self.enumeration(["dataFlow", "controlFlow", "dependency"]),
                    "label": Self.string
                ]))
            ])

        case .riskChunk:
            Self.object([
                "assessments": Self.array(Self.object([
                    "id": Self.string,
                    "attention": Self.enumeration(["high", "medium", "low"]),
                    "summary": Self.string,
                    "factors": Self.array(Self.string),
                    "evidence": Self.array(Self.string),
                    "inspect": Self.array(Self.string),
                    "confidence": Self.enumeration(["high", "medium", "low"]),
                    "uncertainty": Self.string
                ]))
            ])

        case .riskMap:
            Self.object([
                "title": Self.string,
                "overview": Self.string,
                "blastRadius": Self.string,
                "blastRadiusLevel": Self.enumeration(["high", "medium", "low"]),
                "risks": Self.array(Self.object([
                    "id": Self.string,
                    "title": Self.string,
                    "attention": Self.enumeration(["high", "medium", "low"]),
                    "whyFlagged": Self.string,
                    "evidence": Self.array(Self.string),
                    "files": Self.array(Self.string),
                    "symbols": Self.array(Self.string),
                    "inspect": Self.array(Self.string),
                    "confidence": Self.enumeration(["high", "medium", "low"]),
                    "uncertainty": Self.string
                ]))
            ])

        case .question:
            Self.object([
                "answer": Self.string,
                "relevantFiles": Self.array(Self.string),
                "evidence": Self.array(Self.string),
                "uncertainty": Self.string
            ])

        case .noteFix:
            Self.object([
                "plan": Self.array(Self.string),
                "affectedFiles": Self.array(Self.string),
                "proposedPatch": Self.string,
                "explanation": Self.string,
                "uncertainty": Self.string
            ])

        }

    }

    private static var string: [String: Any] { ["type": "string"] }

    private static func enumeration(_ values: [String]) -> [String: Any] {
        ["type": "string", "enum": values]
    }

    private static func array(_ item: [String: Any]) -> [String: Any] {
        ["type": "array", "items": item]
    }

    private static func object(_ properties: [String: Any]) -> [String: Any] {
        [
            "type": "object",
            "properties": properties,
            "required": properties.keys.sorted(),
            "additionalProperties": false
        ]
    }
}
