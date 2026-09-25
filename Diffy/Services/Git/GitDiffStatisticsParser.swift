import Foundation

enum GitDiffStatisticsParser {

    static func counts(_ output: String) -> [String: DiffLineCounts] {

        let records = output.split(separator: "\0", omittingEmptySubsequences: false)
        var counts: [String: DiffLineCounts] = [:]
        var index = 0

        while index < records.count {

            let fields = records[index].split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
            index += 1
            guard fields.count == 3 else { continue }
            var path = String(fields[2])

            if path.isEmpty {

                guard index + 1 < records.count else { break }
                path = String(records[index + 1])
                index += 2

            }

            guard let additions = Int(fields[0]), let deletions = Int(fields[1]) else { continue }
            counts[path] = DiffLineCounts(additions: additions, deletions: deletions)

        }

        return counts

    }

}
