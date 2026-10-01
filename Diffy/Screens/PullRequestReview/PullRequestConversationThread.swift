import Foundation

struct PullRequestConversationThread: Identifiable {
    let entry: PullRequestConversationEntry
    let replies: [PullRequestConversationEntry]

    var id: String { self.entry.id }
}
