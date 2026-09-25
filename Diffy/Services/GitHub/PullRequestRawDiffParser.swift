import Foundation

enum PullRequestRawDiffParser {

    static func snapshots(diff: String, files: [PullRequestReviewFile]) throws -> [AIFileSnapshot] {

        let sections = splitSections(diff)
        let metadata = Dictionary(uniqueKeysWithValues: files.map { ($0.filename, $0) })
        var patches: [String: String] = [:]

        for section in sections {

            guard let path = path(in: section), let file = metadata[path], patches[path] == nil else {
                throw GitHubError.reviewUnavailable("GitHub's raw diff could not be matched to every changed file. Risk Map was not generated.")
            }

            if section.split(separator: "\n").contains(where: { $0.hasPrefix("@@ ") }) {

                let counts = GitPatchParser.lineCounts(section)
                guard counts.additions == file.additions, counts.deletions == file.deletions else {
                    throw GitHubError.reviewUnavailable("GitHub's diff for \(path) was incomplete. Risk Map was not generated.")
                }

            }

            patches[path] = section

        }

        guard patches.count == files.count, sections.count == files.count else {
            throw GitHubError.reviewUnavailable("GitHub's raw diff omitted changed files. Risk Map was not generated.")
        }

        return files.map { file in
            AIFileSnapshot(
                filename: file.filename,
                previousFilename: file.previousFilename,
                status: file.status,
                additions: file.additions,
                deletions: file.deletions,
                patch: patches[file.filename]
            )
        }

    }

    private static func splitSections(_ diff: String) -> [String] {

        var sections: [String] = []
        var current: [Substring] = []

        for line in diff.split(separator: "\n", omittingEmptySubsequences: false) {

            if line.hasPrefix("diff --git "), !current.isEmpty {
                sections.append(current.joined(separator: "\n"))
                current = []
            }
            current.append(line)

        }

        if !current.isEmpty { sections.append(current.joined(separator: "\n")) }
        return sections

    }

    private static func path(in section: String) -> String? {

        let lines = section.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines where line.hasPrefix("+++ ") && line != "+++ /dev/null" {
            return decodePath(String(line.dropFirst(4)))
        }
        for line in lines where line.hasPrefix("rename to ") {
            return decodePath(String(line.dropFirst("rename to ".count)))
        }
        for line in lines where line.hasPrefix("--- ") && line != "--- /dev/null" {
            return decodePath(String(line.dropFirst(4)))
        }

        guard let header = lines.first else { return nil }
        let markers = [" \"b/", " b/"]
        for marker in markers {

            if let range = header.range(of: marker, options: .backwards) {
                return decodePath(String(header[range.lowerBound...].dropFirst()))
            }

        }

        return nil

    }

    private static func decodePath(_ raw: String) -> String? {

        let path: String
        if raw.hasPrefix("\""), raw.hasSuffix("\"") {
            guard let decoded = unescape(String(raw.dropFirst().dropLast())) else { return nil }
            path = decoded
        } else {
            path = raw
        }

        if path.hasPrefix("a/") || path.hasPrefix("b/") {
            return String(path.dropFirst(2))
        }
        return path

    }

    private static func unescape(_ value: String) -> String? {

        let source = Array(value.utf8)
        var result: [UInt8] = []
        var index = 0

        while index < source.count {

            let byte = source[index]
            guard byte == 92, index + 1 < source.count else {
                result.append(byte)
                index += 1
                continue
            }

            index += 1
            let escaped = source[index]
            if escaped >= 48 && escaped <= 55 {

                var octal = Int(escaped - 48)
                var digits = 1
                while digits < 3, index + 1 < source.count,
                      source[index + 1] >= 48, source[index + 1] <= 55 {
                    index += 1
                    digits += 1
                    octal = octal * 8 + Int(source[index] - 48)
                }
                guard let decoded = UInt8(exactly: octal) else { return nil }
                result.append(decoded)

            } else {

                let decoded: UInt8
                switch escaped {
                case 116: decoded = 9
                case 110: decoded = 10
                case 114: decoded = 13
                default: decoded = escaped
                }
                result.append(decoded)

            }

            index += 1

        }

        return String(data: Data(result), encoding: .utf8)

    }

}
