import Foundation

extension LearningPathStep {

    var orderedFiles: [String] {

        var seen = Set<String>()
        return (self.suggestedFiles + self.relevantFiles).filter { seen.insert($0).inserted }

    }

    var markdownCodeLinks: [String: URL] {

        var candidates: [String: [LearningPathCodeReference]] = [:]
        for reference in self.codeReferences {

            let names = [reference.label, reference.filePath, (reference.filePath as NSString).lastPathComponent]
            for name in names {
                candidates[name, default: []].append(reference)
            }

        }

        // Ambiguous symbols or basenames stay plain text instead of opening the wrong file.
        return candidates.reduce(into: [:]) { links, item in

            let paths = Set(item.value.map(\.filePath))
            if paths.count == 1, let url = item.value.first?.url {
                links[item.key] = url
            }

        }

    }

    func filePath(for url: URL) -> String? {
        self.codeReferences.first { $0.url == url }?.filePath
    }

}
