import SwiftUI

struct DiffCanvasHeightPreference: PreferenceKey {

    static let defaultValue: CGFloat = 120

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }

}
