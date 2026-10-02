import Foundation

struct FileNavigatorInput: Equatable {
    let files: [DiffFile]
    let mode: ComparisonMode
    let query: String
    let sort: FileSortOrder
    let ascending: Bool
    let filter: FileChangeStatus?
    /// Updated sorting uses minute-relative timestamps.
    let dateMinute: Int?
}
