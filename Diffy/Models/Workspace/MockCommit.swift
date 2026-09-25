import Foundation

struct MockCommit: Identifiable, Hashable {

    let id: String
    let title: String
    let author: String
    let date: String
    let additions: Int
    let deletions: Int

}
