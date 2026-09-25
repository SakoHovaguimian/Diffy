import Foundation

extension LiveGitService {

    func patch(in repository: GitRepositoryReference, selection: ComparisonSelection) async throws -> String {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        let arguments = try await comparisonArguments(selection, at: url)
        let output = try await self.runner.run(["diff", "--no-ext-diff", "--no-textconv", "--stat", "--patch", "--find-renames"] + arguments, directory: url)

        if selection == .workingTree || selection.right == .workingTree {

            let state = try await snapshot(of: repository, scope: .status, previous: nil)
            let untracked = state.changes.filter { $0.isUntracked && (selection.paths.isEmpty || selection.paths.contains($0.path)) }
            var result = output.text

            for change in untracked.prefix(100) {

                let extra = try await self.runner.run(["diff", "--no-index", "--no-ext-diff", "--no-textconv", "--", "/dev/null", change.path], directory: url, acceptsFailure: true)

                guard extra.status <= 1 else {
                    throw GitError.unsupported(extra.error)
                }

                result += extra.text

                guard result.utf8.count <= 8_000_000 else {
                    throw GitError.unsupported("Select one file to inspect this large comparison.")
                }

            }

            if untracked.count > 100 {
                result += "\nShowing the first 100 untracked files. Select a file to inspect it individually.\n"
            }

            return result

        }

        return output.text

    }

    func comparisonArguments(_ selection: ComparisonSelection, at url: URL) async throws -> [String] {

        try selection.paths.forEach(validatePath)
        var arguments: [String]

        switch (selection.left, selection.right) {

        case (.index, .workingTree):
            arguments = []

        case (.head, .index):
            arguments = ["--cached"]

        case (_, .workingTree):
            arguments = [try await sourceRevision(selection.left, at: url)]

        default:
            let left = try await sourceRevision(selection.left, at: url)
            let right = try await sourceRevision(selection.right, at: url)
            arguments = selection.usesMergeBase ? [left + "..." + right] : [left, right]

        }

        return arguments + ["--"] + selection.paths

    }

    private func sourceRevision(_ source: ComparisonSource, at url: URL) async throws -> String {

        switch source {

        case .head:
            return try await resolvedRevision("HEAD", at: url)

        case let .revision(revision):
            return try await resolvedRevision(revision, at: url)

        case let .parent(commit):
            let identifier = try await resolvedRevision(commit, at: url)
            let parent = try await self.runner.run(["rev-parse", "--verify", identifier + "^"], directory: url, acceptsFailure: true)

            if parent.status == 0 {
                return parent.trimmed
            }

            // The empty tree handles the initial commit for both SHA-1 and SHA-256 repos.
            return try await self.runner.run(["hash-object", "-t", "tree", "--stdin"], directory: url).trimmed

        case .index, .workingTree:
            throw GitError.unsupported("Choose a commit or branch for this side of the comparison.")

        }

    }

    func trackedPaths(in repository: GitRepositoryReference) async throws -> [String] {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        let result = try await self.runner.run(["ls-files", "-z"], directory: url)
        return Array(Set(result.text.split(separator: "\0").map(String.init))).sorted()

    }

    func fileComparison(in repository: GitRepositoryReference, selection: ComparisonSelection, file: DiffFile) async throws -> DiffFile {

        guard file.status != .conflicted else {
            throw GitError.unsupported("This file has unresolved conflicts. Open Merge to choose a side or stage your resolution.")
        }

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        var selected = selection
        selected.paths = [file.path] + (file.originalPath.map { [$0] } ?? [])
        let arguments = try await comparisonArguments(selected, at: url)
        let options = ["--no-ext-diff", "--no-textconv", "--no-color", "--find-renames", "--unified=1000000"]
        var output = try await self.runner.run(["diff"] + options + arguments, directory: url)

        if output.data.isEmpty, file.status == .added, selection.right == .workingTree {

            output = try await self.runner.run(["diff", "--no-index"] + options + ["--", "/dev/null", file.path], directory: url, acceptsFailure: true)

            guard output.status <= 1 else {
                throw GitError.unsupported(output.error)
            }

        }

        let isBinary = output.text.components(separatedBy: "\n").contains {
            $0.hasPrefix("Binary files ") || $0 == "GIT binary patch"
        }
        let kind: ComparisonFileKind = file.kind == .image ? .image : (isBinary ? .binary : .text)
        let lines = kind == .text ? GitPatchParser.lines(output.text) : []

        if lines.isEmpty, kind == .text {
            return try await unchangedContent(in: repository, selection: selection, file: file)
        }

        return file.replacingContent(lines: lines, kind: kind)

    }

    private func unchangedContent(in repository: GitRepositoryReference, selection: ComparisonSelection, file: DiffFile) async throws -> DiffFile {

        let sources = try await imageSources(in: repository, selection: selection, file: file)
        let data = sources.updated ?? sources.original ?? Data()

        guard !data.contains(0), let text = String(data: data, encoding: .utf8) else {
            return file.replacingContent(lines: [], kind: .binary)
        }

        var sourceLines = text.isEmpty ? [] : text.components(separatedBy: "\n")

        if text.hasSuffix("\n") {
            sourceLines.removeLast()
        }

        let lines = sourceLines.enumerated().map { index, source in
            DiffLine(id: index, oldNumber: index + 1, newNumber: index + 1, left: source, right: source, status: .identical)
        }
        return file.replacingLines(lines)

    }

    func imageSources(in repository: GitRepositoryReference, selection: ComparisonSelection, file: DiffFile) async throws -> ImageComparisonSources {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        try validatePath(file.path)
        var leftSource = selection.left

        if selection.usesMergeBase {

            let leftRevision = try await sourceRevision(selection.left, at: url)
            let rightRevision = try await sourceRevision(selection.right, at: url)
            let mergeBase = try await self.runner.run(["merge-base", leftRevision, rightRevision], directory: url)
            leftSource = .revision(mergeBase.trimmed)

        }

        let left = file.status == .added ? nil : try await content(leftSource, path: file.originalPath ?? file.path, at: url)
        let right = file.status == .removed ? nil : try await content(selection.right, path: file.path, at: url)
        return ImageComparisonSources(original: left, updated: right)

    }

    func content(_ source: ComparisonSource, path: String, at url: URL) async throws -> Data? {

        try validatePath(path)

        if source == .workingTree {

            let fileURL = url.appendingPathComponent(path).resolvingSymlinksInPath()

            guard fileURL.path.hasPrefix(url.resolvingSymlinksInPath().path + "/") else {
                throw GitError.invalidPath(path)
            }

            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return nil
            }

            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: 8_000_001) ?? Data()

            guard data.count <= 8_000_000 else {
                throw GitError.unsupported("This file exceeds the 8 MB preview limit.")
            }

            return data

        }

        let revision = source == .index ? "" : try await sourceRevision(source, at: url)
        let output = try await self.runner.run(["show", revision + ":" + path], directory: url, acceptsFailure: true)
        return output.status == 0 ? output.data : nil

    }

    func folderPatch(left: URL, right: URL) async throws -> String {

        let leftAccess = left.startAccessingSecurityScopedResource()
        let rightAccess = right.startAccessingSecurityScopedResource()
        defer { if leftAccess { left.stopAccessingSecurityScopedResource() } }
        defer { if rightAccess { right.stopAccessingSecurityScopedResource() } }
        let result = try await self.runner.run(["diff", "--no-index", "--no-ext-diff", "--no-textconv", "--", left.path, right.path], directory: FileManager.default.temporaryDirectory, acceptsFailure: true)

        guard result.status <= 1 else {
            throw GitError.unsupported(result.error)
        }

        return result.text

    }

    func folderComparisonFiles(left: URL, right: URL) async throws -> [DiffFile] {

        let leftAccess = left.startAccessingSecurityScopedResource()
        let rightAccess = right.startAccessingSecurityScopedResource()
        defer { if leftAccess { left.stopAccessingSecurityScopedResource() } }
        defer { if rightAccess { right.stopAccessingSecurityScopedResource() } }
        let leftFiles = folderContents(at: left)
        let rightFiles = folderContents(at: right)
        let paths = Set(leftFiles.keys).union(rightFiles.keys)

        return paths.map { path in

            let original = leftFiles[path]
            let updated = rightFiles[path]
            let status: FileChangeStatus

            if original == nil {
                status = .added
            } else if updated == nil {
                status = .removed
            } else if let original, let updated {
                status = FileManager.default.contentsEqual(atPath: original.path, andPath: updated.path) ? .identical : .modified
            } else {
                status = .modified
            }

            let url = updated ?? original
            let values = try? url?.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            return DiffFile(
                id: path, path: path, originalPath: nil, status: status,
                kind: comparisonKind(path: path), isStaged: false,
                lastEditedAt: values?.contentModificationDate, size: values?.fileSize ?? 0,
                lines: [], isContentLoaded: false
            )

        }
        .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

    }

    func folderFileComparison(left: URL, right: URL, file: DiffFile) async throws -> DiffFile {
        file.replacingLines(GitPatchParser.lines(try await folderFilePatch(left: left, right: right, path: file.path)))
    }

    func folderFilePatch(left: URL, right: URL, path: String) async throws -> String {

        try validatePath(path)
        let leftAccess = left.startAccessingSecurityScopedResource()
        let rightAccess = right.startAccessingSecurityScopedResource()
        defer { if leftAccess { left.stopAccessingSecurityScopedResource() } }
        defer { if rightAccess { right.stopAccessingSecurityScopedResource() } }
        let original = left.appendingPathComponent(path)
        let updated = right.appendingPathComponent(path)
        let leftPath = FileManager.default.fileExists(atPath: original.path) ? original.path : "/dev/null"
        let rightPath = FileManager.default.fileExists(atPath: updated.path) ? updated.path : "/dev/null"
        let output = try await self.runner.run(
            ["diff", "--no-index", "--no-ext-diff", "--no-textconv", "--no-color", "--unified=1000000", "--", leftPath, rightPath],
            directory: FileManager.default.temporaryDirectory, acceptsFailure: true
        )
        guard output.status <= 1 else { throw GitError.unsupported(output.error) }
        return output.text

    }

    private func folderContents(at root: URL) -> [String: URL] {

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
            options: []
        ) else { return [:] }

        var files: [String: URL] = [:]

        for case let url as URL in enumerator {

            let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values?.isRegularFile == true || values?.isSymbolicLink == true else { continue }
            let path = String(url.path.dropFirst(root.path.count + 1))
            files[path] = url

        }

        return files
    }

}
