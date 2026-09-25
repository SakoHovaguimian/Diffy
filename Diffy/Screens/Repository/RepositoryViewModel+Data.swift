import Foundation

extension RepositoryViewModel {

    func loadPaths() async {

        guard let reference else { return }
        let requestID = UUID()
        let branch = self.historyBranch
        let revision = browsingRevision(for: branch)
        self.pathInventoryRequestID = requestID
        self.isLoadingHistoryFiles = true
        self.isLoadingHistory = !self.historyPath.isEmpty
        self.historyFilesError = nil

        do {

            let entries = try await self.git.fileInventory(in: reference, revision: revision)
            guard self.reference == reference,
                  self.historyBranch == branch,
                  self.pathInventoryRequestID == requestID else {
                return
            }
            self.pathEntries = entries
            self.trackedPaths = entries.map(\.path)
            self.isLoadingHistoryFiles = false

            if !self.historyPath.isEmpty {

                if entries.contains(where: { $0.path == self.historyPath }) {
                    await loadHistory(path: self.historyPath)
                } else {
                    self.historyPath = ""
                    self.history = []
                    self.isLoadingHistory = false
                }

            }

        } catch {

            guard self.reference == reference,
                  self.historyBranch == branch,
                  self.pathInventoryRequestID == requestID else {
                return
            }
            self.historyFilesError = error.localizedDescription
            self.isLoadingHistoryFiles = false
            self.isLoadingHistory = false

        }

    }

    func loadHistory(path: String, more: Bool = false) async {

        guard let reference else { return }
        let requestID = UUID()
        let branch = self.historyBranch
        let revision = browsingRevision(for: branch)
        self.historyRequestID = requestID
        self.historyPath = path
        self.historyLimit = more ? min(500, self.historyLimit + 50) : 50
        self.isLoadingHistory = true
        self.patchError = nil
        let requestedLimit = self.historyLimit

        do {

            let history = try await self.git.fileHistory(in: reference, revision: revision, path: path, limit: requestedLimit)
            guard self.reference == reference,
                  self.historyBranch == branch,
                  self.historyRequestID == requestID else {
                return
            }
            self.history = history
            self.isLoadingHistory = false

        } catch {

            guard self.reference == reference,
                  self.historyBranch == branch,
                  self.historyRequestID == requestID else {
                return
            }
            self.patchError = error.localizedDescription
            self.isLoadingHistory = false

        }

    }

    func loadCommits() async {

        guard let reference else { return }
        let requestID = UUID()
        let branch = self.commitsBranch
        let revision = browsingRevision(for: branch)
        self.commitsRequestID = requestID
        self.isLoadingCommits = true
        self.commitsError = nil

        if revision == nil, self.snapshot?.head.isUnborn == true {
            self.branchCommits = []
            self.isLoadingCommits = false
            return
        }

        do {

            let commits = try await self.git.commits(in: reference, revision: revision, limit: 50)
            guard self.reference == reference,
                  self.commitsBranch == branch,
                  self.commitsRequestID == requestID else {
                return
            }
            self.branchCommits = commits
            self.isLoadingCommits = false

        } catch {

            guard self.reference == reference,
                  self.commitsBranch == branch,
                  self.commitsRequestID == requestID else {
                return
            }
            self.commitsError = error.localizedDescription
            self.isLoadingCommits = false

        }

    }

    func loadPullRequests() async {

        guard let link = self.linkedRepository,
              let account = self.availableAccounts.first(where: { $0.id == self.selectedAccountID }) else {
            return
        }

        let requestID = UUID()
        self.pullRequestsRequestID = requestID
        self.isLoadingPullRequests = true
        self.isLoadingChecks = false
        self.pullRequestError = nil
        let projectID = self.project?.id

        do {

            let result = try await self.gitHub.unmergedPullRequests(for: link, account: account, validators: .none)
            guard self.project?.id == projectID, self.pullRequestsRequestID == requestID, self.selectedAccountID == account.id else { return }
            self.pullRequests = result.value ?? []
            self.isLoadingPullRequests = false
            await loadChecks(link: link, account: account, requestID: requestID)

        } catch {

            guard self.project?.id == projectID, self.pullRequestsRequestID == requestID else { return }
            self.pullRequestError = error.localizedDescription
            self.isLoadingPullRequests = false

            if case GitHubError.reauthorizationRequired = error {
                try? self.accounts.markRequiresReauthorization(account)
            }

        }

    }

    private func loadChecks(link: GitHubRepositoryLink, account: GitHubAccount, requestID: UUID) async {

        let requests = self.pullRequests
        guard !requests.isEmpty else { return }
        self.isLoadingChecks = true

        await withTaskGroup(of: (Int, PullRequestChecksSummary).self) { group in

            var remaining = requests.makeIterator()

            for _ in 0..<min(6, requests.count) {
                if let request = remaining.next() {
                    group.addTask { [gitHub] in
                        (request.id, await gitHub.checksSummary(for: request, link: link, account: account))
                    }
                }
            }

            for await (id, checks) in group {

                guard self.pullRequestsRequestID == requestID, !Task.isCancelled else {
                    group.cancelAll()
                    return
                }

                if let index = self.pullRequests.firstIndex(where: { $0.id == id }) {
                    self.pullRequests[index].checks = checks
                }

                if let request = remaining.next() {
                    group.addTask { [gitHub] in
                        (request.id, await gitHub.checksSummary(for: request, link: link, account: account))
                    }
                }

            }

        }

        if self.pullRequestsRequestID == requestID {
            self.isLoadingChecks = false
        }

    }

    func compareFolders() {

        guard let left = self.leftFolder, let right = self.rightFolder else { return }
        self.isLoadingPatch = true
        self.showsPatch = true
        self.patchError = nil
        self.patchText = ""
        self.patchTitle = "\(left.lastPathComponent) → \(right.lastPathComponent)"
        let projectID = self.project?.id

        self.patchTask?.cancel()
        self.patchTask = Task {

            do {

                let files = try await self.git.folderComparisonFiles(left: left, right: right)
                try Task.checkCancellation()
                guard self.project?.id == projectID else { return }
                self.folderEntries = files.map { file in
                    RepositoryPathEntry(path: file.path, gitUpdatedAt: nil, diskUpdatedAt: file.lastEditedAt, isTracked: false, prefersDiskTime: true, status: file.status)
                }
                self.folderExpandedFolders = Set(self.folderEntries.compactMap { $0.path.split(separator: "/").first.map(String.init) })
                self.selectedFolderPath = nil
                self.patchText = try await self.git.folderPatch(left: left, right: right)

            } catch is CancellationError {
                return
            } catch {

                guard !Task.isCancelled, self.project?.id == projectID else { return }
                self.patchError = error.localizedDescription

            }

            self.isLoadingPatch = false

        }

    }

    func inspectFolderFile(_ path: String) {

        guard let left = self.leftFolder, let right = self.rightFolder else { return }
        self.selectedFolderPath = path
        self.patchTitle = path
        self.patchError = nil
        self.patchText = ""
        self.isLoadingPatch = true
        self.showsPatch = true
        self.patchTask?.cancel()

        self.patchTask = Task {

            do {
                self.patchText = try await self.git.folderFilePatch(left: left, right: right, path: path)
            } catch is CancellationError {
                return
            } catch {
                self.patchError = error.localizedDescription
            }

            self.isLoadingPatch = false

        }

    }

}
