import Foundation

struct MergeConflict: Hashable, Identifiable, Sendable {

    let id: Int
    let title: String
    let base: String
    let yours: String
    let theirs: String

}
