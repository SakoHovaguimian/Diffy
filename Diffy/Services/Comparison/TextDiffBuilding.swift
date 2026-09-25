import Foundation

protocol TextDiffBuilding {
    func lines(original: [String], updated: [String]) -> [DiffLine]
}
