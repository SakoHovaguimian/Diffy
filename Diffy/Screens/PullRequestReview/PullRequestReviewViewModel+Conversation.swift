import Foundation

@MainActor
extension PullRequestReviewViewModel {

    func makeConversationThreads() -> [PullRequestConversationThread] {

        let entries = self.conversation.sorted { first, second in

            let firstDate = first.date ?? .distantPast
            let secondDate = second.date ?? .distantPast
            return firstDate == secondDate ? first.id < second.id : firstDate < secondDate

        }
        let inlineEntries = Dictionary(uniqueKeysWithValues: entries.filter { $0.kind == .inline }.map { ($0.remoteID, $0) })
        let rootIDs = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, conversationRoot(for: $0, in: inlineEntries).id) })
        let replies = Dictionary(grouping: entries.filter { rootIDs[$0.id] != $0.id }) { rootIDs[$0.id] ?? $0.id }

        return entries.filter { rootIDs[$0.id] == $0.id }.map { entry in
            PullRequestConversationThread(entry: entry, replies: replies[entry.id] ?? [])
        }

    }

    var conversationReviewCount: Int {
        self.conversation.filter { $0.kind == .review }.count
    }

    var conversationCommentCount: Int {
        self.conversation.filter { $0.kind != .review }.count
    }

    // MARK: - Code Locations

    func conversationLocation(for entry: PullRequestConversationEntry) -> PullRequestConversationEntry {
        self.conversationLocations[entry.id] ?? entry
    }

    func makeConversationLocations() -> [String: PullRequestConversationEntry] {

        let inlineEntries = Dictionary(uniqueKeysWithValues: self.conversation.filter { $0.kind == .inline }.map { ($0.remoteID, $0) })

        return Dictionary(uniqueKeysWithValues: self.conversation.map { entry in

            let location = entry.line == nil && entry.replyToID != nil ? conversationRoot(for: entry, in: inlineEntries) : entry
            return (entry.id, location)

        })

    }

    func openConversationComment(_ entry: PullRequestConversationEntry) {

        guard entry.kind == .inline else { return }
        let location = conversationLocation(for: entry)
        guard let path = entry.path ?? location.path else { return }
        guard let file = self.details?.files.first(where: { $0.filename == path || $0.previousFilename == path }),
              let fileViewModel = self.reviewFile(for: file.id) else {

            self.notice = "This comment refers to a file outside the loaded revision. View the discussion on GitHub to see its original context."
            return

        }

        openFile(path: path)
        fileViewModel.navigate(to: entry, location: location)

    }

    // MARK: - Thread Ownership

    private func conversationRoot(
        for entry: PullRequestConversationEntry,
        in inlineEntries: [Int: PullRequestConversationEntry]
    ) -> PullRequestConversationEntry {

        guard entry.kind == .inline else { return entry }
        var current = entry
        var visitedIDs: Set<Int> = []

        while let parentID = current.replyToID, let parent = inlineEntries[parentID] {

            guard visitedIDs.insert(current.remoteID).inserted else { return entry }
            current = parent

        }

        return current

    }

}
