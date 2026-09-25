import Foundation

struct MockTextDiffBuilder: TextDiffBuilding {

    func lines(original: [String], updated: [String]) -> [DiffLine] {

        let matches = matchingLines(original: original, updated: updated)
        var lines: [DiffLine] = []
        var originalIndex = 0
        var updatedIndex = 0

        for match in matches {

            appendChangedBlock(
                original: original,
                updated: updated,
                originalRange: originalIndex..<match.original,
                updatedRange: updatedIndex..<match.updated,
                to: &lines
            )
            appendLine(
                left: original[match.original],
                right: updated[match.updated],
                oldNumber: match.original + 1,
                newNumber: match.updated + 1,
                status: .identical,
                to: &lines
            )

            originalIndex = match.original + 1
            updatedIndex = match.updated + 1

        }

        appendChangedBlock(
            original: original,
            updated: updated,
            originalRange: originalIndex..<original.count,
            updatedRange: updatedIndex..<updated.count,
            to: &lines
        )

        return lines

    }

    // This intentionally small line matcher powers only editable prototype drafts.
    private func matchingLines(original: [String], updated: [String]) -> [(original: Int, updated: Int)] {

        var lengths = Array(
            repeating: Array(repeating: 0, count: updated.count + 1),
            count: original.count + 1
        )

        for originalIndex in original.indices.reversed() {

            for updatedIndex in updated.indices.reversed() {

                if original[originalIndex] == updated[updatedIndex] {
                    lengths[originalIndex][updatedIndex] = lengths[originalIndex + 1][updatedIndex + 1] + 1
                } else {
                    lengths[originalIndex][updatedIndex] = max(
                        lengths[originalIndex + 1][updatedIndex],
                        lengths[originalIndex][updatedIndex + 1]
                    )
                }

            }

        }

        var matches: [(original: Int, updated: Int)] = []
        var originalIndex = 0
        var updatedIndex = 0

        while originalIndex < original.count, updatedIndex < updated.count {

            if original[originalIndex] == updated[updatedIndex] {

                matches.append((originalIndex, updatedIndex))
                originalIndex += 1
                updatedIndex += 1

            } else if lengths[originalIndex + 1][updatedIndex] >= lengths[originalIndex][updatedIndex + 1] {
                originalIndex += 1
            } else {
                updatedIndex += 1
            }

        }

        return matches

    }

    private func appendChangedBlock(
        original: [String],
        updated: [String],
        originalRange: Range<Int>,
        updatedRange: Range<Int>,
        to lines: inout [DiffLine]
    ) {

        let pairedCount = min(originalRange.count, updatedRange.count)

        for offset in 0..<pairedCount {

            let originalIndex = originalRange.lowerBound + offset
            let updatedIndex = updatedRange.lowerBound + offset

            appendLine(
                left: original[originalIndex],
                right: updated[updatedIndex],
                oldNumber: originalIndex + 1,
                newNumber: updatedIndex + 1,
                status: .modified,
                to: &lines
            )

        }

        for originalIndex in originalRange.dropFirst(pairedCount) {

            appendLine(
                left: original[originalIndex],
                right: nil,
                oldNumber: originalIndex + 1,
                newNumber: nil,
                status: .removed,
                to: &lines
            )

        }

        for updatedIndex in updatedRange.dropFirst(pairedCount) {

            appendLine(
                left: nil,
                right: updated[updatedIndex],
                oldNumber: nil,
                newNumber: updatedIndex + 1,
                status: .added,
                to: &lines
            )

        }

    }

    private func appendLine(
        left: String?,
        right: String?,
        oldNumber: Int?,
        newNumber: Int?,
        status: FileChangeStatus,
        to lines: inout [DiffLine]
    ) {

        lines.append(DiffLine(
            id: lines.count,
            oldNumber: oldNumber,
            newNumber: newNumber,
            left: left,
            right: right,
            status: status
        ))

    }

}
