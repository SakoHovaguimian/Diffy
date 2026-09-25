import Foundation
import Combine

@MainActor
final class GitHubAccountsViewModel: ViewModel {

    let loggerName = "GIT_HUB_ACCOUNTS_VIEW_MODEL"
    let runtime: AppRuntime
    let accountService: GitHubAccountServiceProtocol
    private let gitHub: GitHubServiceProtocol
    private let git: GitServiceProtocol
    private let workspace: WorkspaceServiceProtocol
    private var authorizationTask: Task<Void, Never>?
    private var repositoryRequest = UUID()
    private var nextPage = 1

    @Published private(set) var accounts: [GitHubAccount]
    @Published private(set) var repositories: [GitHubRepositorySummary] = []
    @Published private(set) var authorization: GitHubSignInChallenge?
    @Published private(set) var isSigningIn = false
    @Published private(set) var isLoadingRepositories = false
    @Published private(set) var isImporting = false
    @Published private(set) var hasMoreRepositories = false
    @Published private(set) var libraryRevision = 0
    @Published var selectedAccountID: String = ""
    @Published var search = ""
    @Published var personalAccessToken = ""
    @Published var showsToken = false
    @Published var errorMessage: String?
    @Published var notice: String?
    @Published var accountToRemove: GitHubAccount?
    @Published var cloneTransport: GitCloneTransport = .https

    init(
        runtime: AppRuntime,
        accountService: GitHubAccountServiceProtocol,
        gitHub: GitHubServiceProtocol,
        git: GitServiceProtocol,
        workspace: WorkspaceServiceProtocol
    ) {

        self.runtime = runtime
        self.accountService = accountService
        self.gitHub = gitHub
        self.git = git
        self.workspace = workspace
        self.accounts = accountService.loadAccounts()
        self.selectedAccountID = self.accounts.first?.id ?? ""

    }

    var selectedAccount: GitHubAccount? {
        self.accounts.first { $0.id == self.selectedAccountID }
    }

    var visibleRepositories: [GitHubRepositorySummary] {
        self.repositories.filter { self.search.isEmpty || $0.fullName.localizedStandardContains(self.search) }
    }

    func signIn(reconnecting account: GitHubAccount? = nil) {

        guard !self.isSigningIn else { return }
        self.isSigningIn = true
        self.errorMessage = nil
        self.authorizationTask = Task {

            defer { self.isSigningIn = false }

            do {

                if self.accountService.configuration.isConfigured {

                    let authorization = try await self.accountService.beginDeviceAuthorization(reconnecting: account)
                    self.authorization = GitHubSignInChallenge(userCode: authorization.userCode, verificationURL: authorization.verificationURL, expiresAt: authorization.expiresAt, providerName: "Diffy")
                    connected(try await self.accountService.completeDeviceAuthorization(authorization))

                } else {

                    let connectedAccount = try await self.accountService.signInUsingCLI(reconnecting: account) { [weak self] challenge in

                        Task { @MainActor in
                            if self?.isSigningIn == true { self?.authorization = challenge }
                        }

                    }
                    connected(connectedAccount)

                }

            } catch is CancellationError {
                self.authorization = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.authorization = nil

        }

    }

    func connectToken() {

        guard !self.isSigningIn else { return }
        let token = self.personalAccessToken
        self.personalAccessToken = ""
        self.isSigningIn = true
        self.errorMessage = nil
        self.authorizationTask = Task {

            defer { self.isSigningIn = false }

            do {
                connected(try await self.accountService.connect(personalAccessToken: token))
            } catch is CancellationError {
                return
            } catch {
                self.errorMessage = error.localizedDescription
            }

        }

    }

    func cancelSignIn() {

        self.authorizationTask?.cancel()
        self.authorization = nil

    }

    private func connected(_ account: GitHubAccount) {

        self.accounts = self.accountService.loadAccounts()
        self.selectedAccountID = account.id
        self.notice = "Connected as \(account.handle). Choose a repository to link or clone."
        Task { await loadRepositories() }

    }

    func refreshAccounts() {
        self.accounts = self.accountService.loadAccounts()
    }

    func removeAccount(_ account: GitHubAccount) async {

        do {

            try await self.accountService.removeAccount(account)
            self.accounts = self.accountService.loadAccounts()

            if self.selectedAccountID == account.id {
                self.selectedAccountID = self.accounts.first?.id ?? ""
            }

            self.notice = "Disconnected \(account.handle). Local projects and folders are preserved."
            self.accountToRemove = nil

        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    func loadRepositories(loadMore: Bool = false) async {

        guard let account = self.selectedAccount else {

            self.repositories = []
            return

        }

        if loadMore && self.isLoadingRepositories { return }
        let request = UUID()
        self.repositoryRequest = request
        self.isLoadingRepositories = true
        self.errorMessage = nil
        let page = loadMore ? self.nextPage : 1

        if !loadMore { self.repositories = [] }
        defer { if self.repositoryRequest == request { self.isLoadingRepositories = false } }

        do {

            let repositories = try await self.gitHub.accessibleRepositories(for: account, page: page)
            guard request == self.repositoryRequest, account.id == self.selectedAccountID else { return }
            let existing = loadMore ? self.repositories : []
            self.repositories = existing + repositories.filter { item in !existing.contains { $0.id == item.id } }
            self.nextPage = page + 1
            self.hasMoreRepositories = repositories.count == 50

        } catch is CancellationError {
            return
        } catch {

            guard request == self.repositoryRequest else { return }
            self.errorMessage = error.localizedDescription

            if case GitHubError.reauthorizationRequired = error {
                try? self.accountService.markRequiresReauthorization(account)
            }

            refreshAccounts()

        }

    }

    func link(_ repository: GitHubRepositorySummary, folder: URL, clone: Bool) {

        guard let account = self.selectedAccount, !self.isImporting else { return }
        self.isImporting = true
        self.errorMessage = nil
        let transport = self.cloneTransport

        Task {

            defer { self.isImporting = false }

            do {

                let directory: URL

                if clone {

                    let request = GitCloneRequest(remoteURL: transport.remoteURL(for: repository), parentDirectory: folder, directoryName: repository.coordinate.name)
                    self.notice = "Cloning \(repository.fullName)…"
                    directory = try await self.git.clone(request) { _ in }

                } else {
                    directory = folder
                }

                let checkout = try self.workspace.makeCheckoutReference(for: directory)
                let reference = GitRepositoryReference(projectID: UUID().uuidString, checkout: checkout)
                let snapshot = try await self.git.snapshot(of: reference, scope: .full, previous: nil)
                let remote = snapshot.remotes.first { $0.gitHubCoordinate == repository.coordinate }

                guard let remote else {
                    throw GitHubError.forbidden("This folder's remotes do not match \(repository.fullName). Choose its checkout or clone the repository.")
                }

                try saveProject(repository: repository, account: account, checkout: checkout, remote: remote.name)
                self.notice = "\(repository.coordinate.name) is ready in your workspace."
                self.libraryRevision += 1

            } catch {
                self.errorMessage = error.localizedDescription
            }

        }

    }

    private func saveProject(repository: GitHubRepositorySummary, account: GitHubAccount, checkout: LocalCheckoutReference, remote: String) throws {

        var projects = self.workspace.loadLibrary().projects
        let existing = projects.first { $0.checkout?.lastKnownPath == checkout.lastKnownPath }
        var project = existing ?? RepositoryProject(id: UUID().uuidString, name: repository.coordinate.name, subtitle: repository.fullName, bucketID: "", symbol: "shippingbox.fill", checkout: checkout, gitHubLink: nil, gitHubAccountID: nil, addedAt: Date())
        project.checkout = checkout
        project.name = repository.coordinate.name
        project.gitHubLink = repository.link(remoteName: remote)
        project.gitHubAccountID = account.id
        projects.removeAll { $0.id == project.id }
        projects.append(project)
        try self.workspace.saveProjects(projects)

    }

}
