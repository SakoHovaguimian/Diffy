import Foundation

enum RiskDiffChunker {

    static func batches(files: [AIFileSnapshot]) throws -> [[RiskDiffChunk]] {

        var chunks: [RiskDiffChunk] = []
        for file in files {

            guard let patch = file.patch, !patch.isEmpty else {
                throw AIReviewError.unavailable("The complete diff for \(file.filename) was unavailable. Risk Map was not generated.")
            }

            let parts = split(patch, maximumCharacters: 8_000)
            for (index, text) in parts.enumerated() {
                chunks.append(RiskDiffChunk(
                    id: "",
                    path: file.filename,
                    part: index + 1,
                    totalParts: parts.count,
                    status: file.status,
                    additions: file.additions,
                    deletions: file.deletions,
                    text: text
                ))
            }

        }

        var batches: [[RiskDiffChunk]] = []
        var current: [RiskDiffChunk] = []
        var currentCharacters = 0

        for chunk in chunks {

            if !current.isEmpty && (currentCharacters + chunk.text.count > 16_000 || current.count == 8) {
                batches.append(numbered(current))
                current = []
                currentCharacters = 0
            }
            current.append(chunk)
            currentCharacters += chunk.text.count

        }

        if !current.isEmpty { batches.append(numbered(current)) }
        return batches

    }

    private static func split(_ text: String, maximumCharacters: Int) -> [String] {

        var parts: [String] = []
        var start = text.startIndex

        while start < text.endIndex {

            let end = text.index(start, offsetBy: maximumCharacters, limitedBy: text.endIndex) ?? text.endIndex
            parts.append(String(text[start..<end]))
            start = end

        }

        return parts

    }

    private static func numbered(_ chunks: [RiskDiffChunk]) -> [RiskDiffChunk] {

        chunks.enumerated().map { index, chunk in
            RiskDiffChunk(
                id: "chunk-\(index)",
                path: chunk.path,
                part: chunk.part,
                totalParts: chunk.totalParts,
                status: chunk.status,
                additions: chunk.additions,
                deletions: chunk.deletions,
                text: chunk.text
            )
        }

    }

}
