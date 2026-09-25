import Foundation

struct MergeConflict: Identifiable {

    let id: Int
    let title: String
    let base: String
    let yours: String
    let theirs: String

}
