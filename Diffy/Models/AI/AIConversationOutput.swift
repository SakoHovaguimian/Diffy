import Foundation

enum AIConversationOutput: Codable, Hashable, Sendable {
    case question(AIQuestionResponse)
    case noteFix(AINoteFixResponse)
}
