import Foundation

extension LiveGitService {

    func comparisonFiles(in repository: GitRepositoryReference, selection: ComparisonSelection) async throws -> [DiffFile] {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        let arguments = try await comparisonArguments(selection, at: url)
        let result = try await self.runner.run(["diff", "--name-status", "-z", "--find-renames", "--no-ext-diff", "--no-textconv"] + arguments, directory: url)
        let statistics = try await self.runner.run(["diff", "--numstat", "-z", "--find-renames", "--no-ext-diff", "--no-textconv"] + arguments, directory: url)
        let counts = GitDiffStatisticsParser.counts(statistics.text)
        var files = listedFiles(result.text, selection: selection, at: url).map { file in

            var file = file
            file.lineCounts = counts[file.path]
            return file

        }

        if selection.right == .workingTree {

            let untracked = try await self.runner.run(["ls-files", "--others", "--exclude-standard", "-z", "--"] + selection.paths, directory: url)
            files += untracked.text.split(separator: "\0").map { path in
                listing(path: String(path), originalPath: nil, status: .added, selection: selection, at: url)
            }

        }

        let uniqueFiles = Dictionary(files.map { ($0.path, $0) }, uniquingKeysWith: { first, second in
            first.status == .conflicted ? first : second
        })
        return uniqueFiles.values.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

    }

    private func listedFiles(_ output: String, selection: ComparisonSelection, at url: URL) -> [DiffFile] {

        let fields = output.split(separator: "\0").map(String.init)
        var files: [DiffFile] = []
        var index = 0

        while index + 1 < fields.count {

            let code = fields[index]
            let originalPath = code.hasPrefix("R") || code.hasPrefix("C") ? fields[index + 1] : nil
            let pathIndex = index + (originalPath == nil ? 1 : 2)
            guard pathIndex < fields.count else { break }
            files.append(listing(path: fields[pathIndex], originalPath: originalPath, status: changeStatus(code), selection: selection, at: url))
            index = pathIndex + 1

        }

        return files

    }

    private func listing(path: String, originalPath: String?, status: FileChangeStatus, selection: ComparisonSelection, at url: URL) -> DiffFile {

        let values = selection.right == .workingTree ? try? url.appendingPathComponent(path).resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) : nil

        return DiffFile(
            id: path,
            path: path,
            originalPath: originalPath,
            status: status,
            kind: comparisonKind(path: path),
            isStaged: selection.right == .index,
            lastEditedAt: values?.contentModificationDate,
            size: values?.fileSize ?? 0,
            lines: [],
            isContentLoaded: false
        )

    }

    private func changeStatus(_ code: String) -> FileChangeStatus {

        switch code.first {

        case "A", "C": .added
        case "D": .removed
        case "R": .renamed
        case "U": .conflicted
        default: .modified

        }

    }

    func comparisonKind(path: String) -> ComparisonFileKind {

        let imageExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "heic", "webp", "bmp", "ico"]
        return imageExtensions.contains((path as NSString).pathExtension.lowercased()) ? .image : .text

    }

}
