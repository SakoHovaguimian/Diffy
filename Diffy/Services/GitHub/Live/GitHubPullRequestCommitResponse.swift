import Foundation

struct GitHubPullRequestCommitResponse: Decodable, Sendable {

    struct Commit: Decodable, Sendable {

        struct Author: Decodable, Sendable {
            let name: String
            let date: Date
        }

        let message: String
        let author: Author?
    }

    struct Parent: Decodable, Sendable {
        let sha: String
    }

    let sha: String
    let commit: Commit
    let parents: [Parent]

    var reviewCommit: PullRequestCommit {

        PullRequestCommit(
            id: self.sha,
            title: self.commit.message.components(separatedBy: .newlines).first ?? self.sha,
            message: self.commit.message,
            authorName: self.commit.author?.name ?? "Unknown Author",
            authoredAt: self.commit.author?.date ?? .distantPast,
            parentIDs: self.parents.map(\.sha)
        )

    }
}
