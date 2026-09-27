import SwiftUI

private struct DiffyStatusAnimationModifier<Value: Equatable>: ViewModifier {

    let value: Value
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(self.reduceMotion ? nil : .easeInOut(duration: 0.26), value: self.value)
    }

}

extension View {

    func diffyStatusAnimation<Value: Equatable>(value: Value) -> some View {
        modifier(DiffyStatusAnimationModifier(value: value))
    }

}
