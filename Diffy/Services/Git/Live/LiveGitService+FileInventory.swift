import Foundation

extension LiveGitService {

    func fileInventory(
        in repository: GitRepositoryReference,
        revision: String?
    ) async throws -> [RepositoryPathEntry] {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let root = try await repositoryRoot(at: selectedURL)
        let resolved = try await resolvedInventoryRevision(revision, at: root)
        let inventory = try await inventoryPaths(at: root, revision: resolved)
        let gitDates = await recentGitDates(at: root, revision: resolved)

        return inventory.paths.map { path in

            let diskDate = resolved == nil
                ? try? root.appendingPathComponent(path).resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                : nil
            let isTracked = inventory.trackedPaths.contains(path)
            return RepositoryPathEntry(
                path: path,
                gitUpdatedAt: gitDates[path],
                diskUpdatedAt: diskDate,
                isTracked: isTracked,
                prefersDiskTime: resolved == nil && (!isTracked || inventory.changedPaths.contains(path))
            )

        }
        .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }

    }

    private func resolvedInventoryRevision(_ revision: String?, at root: URL) async throws -> String? {

        guard let revision, !revision.isEmpty else { return nil }
        return try await resolvedRevision(revision, at: root)

    }

    private func inventoryPaths(
        at root: URL,
        revision: String?
    ) async throws -> (paths: Set<String>, trackedPaths: Set<String>, changedPaths: Set<String>) {

        if let revision {

            let tree = try await self.runner.run(["ls-tree", "-r", "--name-only", "-z", revision], directory: root)
            let paths = Set(tree.text.split(separator: "\0").map(String.init))
            return (paths: paths, trackedPaths: paths, changedPaths: [])

        }

        let tracked = try await self.runner.run(["ls-files", "-z", "--cached"], directory: root)
        let untracked = try await self.runner.run(["ls-files", "-z", "--others", "--exclude-standard"], directory: root)
        let status = try await self.runner.run(["status", "--porcelain=v1", "-z", "--untracked-files=all"], directory: root)
        let trackedPaths = Set(tracked.text.split(separator: "\0").map(String.init))
        let changedPaths = Set(GitOutputParser.changes(status.text).map(\.path))
        let paths = trackedPaths.union(untracked.text.split(separator: "\0").map(String.init))
        return (paths: paths, trackedPaths: trackedPaths, changedPaths: changedPaths)

    }

    private func recentGitDates(at root: URL, revision: String?) async -> [String: Date] {

        var arguments = ["log", "-500", "--format=__DIFFY_COMMIT__%ct", "--name-only", "--no-renames"]

        if let revision {
            arguments.append(revision)
        }

        let history = try? await self.runner.run(arguments, directory: root, acceptsFailure: true)

        guard let history, history.status == 0 else { return [:] }
        return recentGitDates(history.text)

    }

    private func recentGitDates(_ output: String) -> [String: Date] {

        var dates: [String: Date] = [:]
        var currentDate: Date?

        for line in output.components(separatedBy: "\n") {

            if line.hasPrefix("__DIFFY_COMMIT__") {
                currentDate = TimeInterval(line.dropFirst("__DIFFY_COMMIT__".count)).map(Date.init(timeIntervalSince1970:))
            } else if !line.isEmpty, let currentDate, dates[line] == nil {
                dates[line] = currentDate
            }

        }

        return dates

    }
}
