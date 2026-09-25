import Foundation

/// Projects loaded at launch, with runtime-specific defaults for navigation state.
struct ProjectLibrary {
    let projects: [RepositoryProject]
    let defaultFavoriteProjectIDs: [String]
    let defaultRecentProjectIDs: [String]
    var migrationNotice: String? = nil
    var loadErrorMessage: String? = nil
}
