import Foundation

/// Recoverable merge drafts, stored outside the repository.
protocol MergeDraftStoreProtocol: Sendable {

    func loadDraft(projectID: String, path: String) async -> MergeDraftRecord?
    func saveDraft(_ draft: MergeDraftRecord) async throws

    /// Keeps the applied draft as the previous generation so an interrupted resolution
    /// can still be recovered.
    func archiveDraft(projectID: String, path: String) async

    func loadPreviousDraft(projectID: String, path: String) async -> MergeDraftRecord?

}
