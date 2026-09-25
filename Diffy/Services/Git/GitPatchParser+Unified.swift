import Foundation

extension GitPatchParser {

    /// Preserves patch order instead of pairing removed and added lines for a split view.
    static func unifiedLines(_ patch: String) -> [DiffLine] {

        var oldNumber = 0
        var newNumber = 0
        var isInHunk = false
        var result: [DiffLine] = []

        for rawLine in patch.components(separatedBy: "\n") {

            if rawLine.hasPrefix("@@ ") {

                let fields = rawLine.split(separator: " ")
                guard fields.count >= 3,
                      let old = Int(fields[1].dropFirst().split(separator: ",")[0]),
                      let new = Int(fields[2].dropFirst().split(separator: ",")[0]) else {
                    isInHunk = false
                    continue
                }
                oldNumber = old
                newNumber = new
                isInHunk = true
                continue

            }

            if rawLine.hasPrefix("diff --git") { isInHunk = false }
            guard isInHunk, let prefix = rawLine.first else { continue }
            let text = String(rawLine.dropFirst())

            switch prefix {

            case "-":
                result.append(DiffLine(id: result.count, oldNumber: oldNumber, newNumber: nil, left: text, right: nil, status: .removed))
                oldNumber += 1

            case "+":
                result.append(DiffLine(id: result.count, oldNumber: nil, newNumber: newNumber, left: nil, right: text, status: .added))
                newNumber += 1

            case " ":
                result.append(DiffLine(id: result.count, oldNumber: oldNumber, newNumber: newNumber, left: text, right: text, status: .identical))
                oldNumber += 1
                newNumber += 1

            default:
                continue

            }

        }

        return result

    }

}
