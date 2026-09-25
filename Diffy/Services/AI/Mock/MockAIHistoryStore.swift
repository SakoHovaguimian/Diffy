import Foundation

actor MockAIHistoryStore: AIHistoryStoreProtocol {

    private var generations: [AIReviewGeneration] = []
    private var conversation: [AIConversationEntry] = []

    func loadGenerations(repositoryIdentity: String, pullRequestNumber: Int) throws -> [AIReviewGeneration] {

        let matching = self.generations.filter {
            $0.repositoryIdentity == repositoryIdentity && $0.pullRequestNumber == pullRequestNumber
        }

        guard matching.allSatisfy(\.hasConsistentContext) else {
            throw AIReviewError.storageUnavailable
        }

        return matching.sorted { $0.createdAt > $1.createdAt }

    }

    func appendGeneration(_ generation: AIReviewGeneration) throws {

        guard generation.hasConsistentContext,
              !self.generations.contains(where: { $0.id == generation.id }) else {
            throw AIReviewError.storageUnavailable
        }

        self.generations.append(generation)

    }

    func loadConversation(repositoryIdentity: String, pullRequestNumber: Int) throws -> [AIConversationEntry] {

        let matching = self.conversation.filter {
            $0.repositoryIdentity == repositoryIdentity && $0.pullRequestNumber == pullRequestNumber
        }

        guard matching.allSatisfy(\.hasConsistentContext) else {
            throw AIReviewError.storageUnavailable
        }

        return matching.sorted { $0.createdAt < $1.createdAt }

    }

    func appendConversation(_ entry: AIConversationEntry) throws {

        guard entry.hasConsistentContext,
              !self.conversation.contains(where: { $0.id == entry.id }) else {
            throw AIReviewError.storageUnavailable
        }

        self.conversation.append(entry)

    }
}
