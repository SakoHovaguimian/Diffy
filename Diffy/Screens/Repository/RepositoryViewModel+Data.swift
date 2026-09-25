import Foundation

extension RepositoryViewModel {

    func loadPaths() async {

        guard let reference else { return }

        do {

            let paths = try await self.git.trackedPaths(in: reference)
            guard self.reference == reference else { return }
            self.trackedPaths = paths

        } catch {
            self.patchError = error.localizedDescription
        }

    }

    func loadHistory(path: String, more: Bool = false) async {

        guard let reference else { return }
        let requestID = UUID()
        self.historyRequestID = requestID
        self.historyPath = path
        self.historyLimit = more ? min(500, self.historyLimit + 50) : 50
        self.isLoadingHistory = true
        self.patchError = nil
        let requestedLimit = self.historyLimit

        do {

            let history = try await self.git.fileHistory(in: reference, path: path, limit: requestedLimit)
            guard self.reference == reference, self.historyRequestID == requestID else { return }
            self.history = history
            self.isLoadingHistory = false

        } catch {

            guard self.reference == reference, self.historyRequestID == requestID else { return }
            self.patchError = error.localizedDescription
            self.isLoadingHistory = false

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
        self.pullRequestError = nil
        let projectID = self.project?.id
        defer { if self.pullRequestsRequestID == requestID { self.isLoadingPullRequests = false } }

        do {

            let result = try await self.gitHub.openPullRequests(for: link, account: account, validators: .none)
            guard self.project?.id == projectID, self.pullRequestsRequestID == requestID, self.selectedAccountID == account.id else { return }
            self.pullRequests = result.value ?? []

        } catch {

            guard self.project?.id == projectID, self.pullRequestsRequestID == requestID else { return }
            self.pullRequestError = error.localizedDescription

            if case GitHubError.reauthorizationRequired = error {
                try? self.accounts.markRequiresReauthorization(account)
            }

        }

    }

    func compareFolders() {

        guard let left = self.leftFolder, let right = self.rightFolder else { return }
        self.isLoadingPatch = true
        self.showsPatch = true
        self.patchError = nil
        self.patchTitle = "\(left.lastPathComponent) → \(right.lastPathComponent)"
        let projectID = self.project?.id

        self.patchTask?.cancel()
        self.patchTask = Task {

            do {

                let patch = try await self.git.folderPatch(left: left, right: right)
                try Task.checkCancellation()
                guard self.project?.id == projectID else { return }
                self.patchText = patch

            } catch is CancellationError {
                return
            } catch {

                guard !Task.isCancelled, self.project?.id == projectID else { return }
                self.patchError = error.localizedDescription

            }

            self.isLoadingPatch = false

        }

    }

}
