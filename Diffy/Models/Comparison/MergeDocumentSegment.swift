import Foundation

/// A slice of a conflicted file. Text preserves exact line terminators, so joining every
/// context slice with one chosen side per conflict reproduces a complete file.
enum MergeDocumentSegment: Hashable, Sendable {
    case context(String)
    case conflict(MergeConflict)
}
