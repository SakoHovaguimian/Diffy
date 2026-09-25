import Foundation

enum GitPatchParser {

    static func lineCounts(_ patch: String) -> DiffLineCounts {

        var additions = 0
        var deletions = 0
        var inHunk = false

        for line in patch.components(separatedBy: "\n") {

            if line.hasPrefix("diff --git") {
                inHunk = false
            } else if line.hasPrefix("@@ ") {
                inHunk = true
            } else if inHunk && line.hasPrefix("+") {
                additions += 1
            } else if inHunk && line.hasPrefix("-") {
                deletions += 1
            }

        }

        return DiffLineCounts(additions: additions, deletions: deletions)

    }

    static func lines(_ patch: String) -> [DiffLine] {

        var oldLine = 0
        var newLine = 0
        var result: [DiffLine] = []
        var removed: [(number: Int, text: String)] = []
        var added: [(number: Int, text: String)] = []
        var inHunk = false

        func appendChanges() {

            for offset in 0..<max(removed.count, added.count) {

                let left = offset < removed.count ? removed[offset] : nil
                let right = offset < added.count ? added[offset] : nil
                let status: FileChangeStatus = left == nil ? .added : (right == nil ? .removed : .modified)
                result.append(DiffLine(id: result.count, oldNumber: left?.number, newNumber: right?.number, left: left?.text, right: right?.text, status: status))

            }

            removed.removeAll(keepingCapacity: true)
            added.removeAll(keepingCapacity: true)

        }

        for line in patch.components(separatedBy: "\n") {

            if line.hasPrefix("@@ ") {

                appendChanges()
                let fields = line.split(separator: " ")
                oldLine = fields.count > 1 ? Int(fields[1].dropFirst().split(separator: ",")[0]) ?? 0 : 0
                newLine = fields.count > 2 ? Int(fields[2].dropFirst().split(separator: ",")[0]) ?? 0 : 0
                inHunk = true
                continue

            }

            if line.hasPrefix("diff --git") {

                appendChanges()
                inHunk = false

            }

            guard inHunk, let prefix = line.first else { continue }
            let text = String(line.dropFirst())

            switch prefix {

            case "-":
                removed.append((oldLine, text))
                oldLine += 1

            case "+":
                added.append((newLine, text))
                newLine += 1

            case " ":
                appendChanges()
                result.append(DiffLine(id: result.count, oldNumber: oldLine, newNumber: newLine, left: text, right: text, status: .identical))
                oldLine += 1
                newLine += 1

            default:
                break

            }

        }

        appendChanges()
        return result

    }

}
