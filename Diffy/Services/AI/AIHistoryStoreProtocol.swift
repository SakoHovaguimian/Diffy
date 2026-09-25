import Foundation

protocol AIHistoryStoreProtocol: Sendable {
    func loadGenerations(repositoryIdentity: String, pullRequestNumber: Int) async throws -> [AIReviewGeneration]
    func appendGeneration(_ generation: AIReviewGeneration) async throws
    func loadConversation(repositoryIdentity: String, pullRequestNumber: Int) async throws -> [AIConversationEntry]
    func appendConversation(_ entry: AIConversationEntry) async throws
}
