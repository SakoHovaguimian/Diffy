import Foundation

@MainActor
final class LiveWorkspaceService: WorkspaceServiceProtocol {

    private enum StorageError: LocalizedError {

        case protectedUnreadableStore

        var errorDescription: String? {
            "Diffy will not overwrite the project library because its existing data could not be read."
        }

    }

    let defaultBuckets = WorkspaceDefaults.starterBuckets
    private let paths: LiveStoragePaths
    private let preferencesService: PreferencesServiceProtocol
    private let accessController: SecurityScopedAccessController
    private let fileManager: FileManager
    private var loadedProjects: [RepositoryProject]?
    private var protectsUnreadableStore = false

    init(
        paths: LiveStoragePaths,
        preferencesService: PreferencesServiceProtocol,
        accessController: SecurityScopedAccessController = SecurityScopedAccessController(),
        fileManager: FileManager = .default
    ) {

        self.paths = paths
        self.preferencesService = preferencesService
        self.accessController = accessController
        self.fileManager = fileManager

    }

    // MARK: - Library

    func loadLibrary() -> ProjectLibrary {

        if let loadedProjects = self.loadedProjects {
            return library(projects: loadedProjects)
        }

        guard self.fileManager.fileExists(atPath: self.paths.projectsFile.path) else {
            return migrateLegacyLibrary()
        }

        do {

            let data = try Data(contentsOf: self.paths.projectsFile)
            let projects = try JSONDecoder().decode([RepositoryProject].self, from: data)
            self.loadedProjects = projects

            return library(projects: projects)

        } catch {

            self.protectsUnreadableStore = true
            self.loadedProjects = []

            return library(
                projects: [],
                loadErrorMessage: "Diffy could not read the saved project library. The original file is protected from overwrite. \(error.localizedDescription)"
            )

        }

    }

    func saveProjects(_ projects: [RepositoryProject]) throws {

        guard !self.protectsUnreadableStore else {
            throw StorageError.protectedUnreadableStore
        }

        let directory = self.paths.projectsFile.deletingLastPathComponent()
        try self.fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(projects)
        try data.write(to: self.paths.projectsFile, options: .atomic)
        self.loadedProjects = projects

    }

    func makeCheckoutReference(for directoryURL: URL) throws -> LocalCheckoutReference {

        let standardizedURL = directoryURL.standardizedFileURL
        let bookmarkData = try self.accessController.makeBookmark(for: standardizedURL)

        return LocalCheckoutReference(
            bookmarkData: bookmarkData,
            lastKnownPath: standardizedURL.path
        )

    }

    // MARK: - Migration

    private func migrateLegacyLibrary() -> ProjectLibrary {

        let records = self.preferencesService.load([LocalProjectRecord].self, key: "projects.local.v1") ?? []

        guard !records.isEmpty else {

            self.loadedProjects = []
            return library(projects: [])

        }

        let migratedAt = Date()
        let projects = records.map { record in

            let checkout = LocalCheckoutReference(
                bookmarkData: nil,
                lastKnownPath: record.directoryPath
            )

            return record.migratedProject(checkout: checkout, migratedAt: migratedAt)

        }

        do {

            try saveProjects(projects)

            return library(
                projects: projects,
                migrationNotice: "Your saved folders were migrated. Select a folder again if macOS asks Diffy to renew access."
            )

        } catch {

            self.loadedProjects = projects

            return library(
                projects: projects,
                loadErrorMessage: "Diffy opened the migrated project list but could not save it. \(error.localizedDescription)"
            )

        }

    }

    private func library(
        projects: [RepositoryProject],
        migrationNotice: String? = nil,
        loadErrorMessage: String? = nil
    ) -> ProjectLibrary {

        ProjectLibrary(
            projects: projects,
            defaultFavoriteProjectIDs: [],
            defaultRecentProjectIDs: Array(projects.prefix(WorkspaceDefaults.maximumRecentProjectCount).map(\.id)),
            migrationNotice: migrationNotice,
            loadErrorMessage: loadErrorMessage
        )

    }

}
