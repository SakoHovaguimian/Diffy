import Foundation

struct FileTreeEntry: Identifiable {
    let id: String
    let title: String
    let depth: Int
    let file: DiffFile?
    let count: Int
}
