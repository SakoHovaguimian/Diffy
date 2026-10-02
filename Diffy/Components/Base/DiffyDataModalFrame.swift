import SwiftUI

private struct DiffyDataModalFrame: ViewModifier {

    func body(content: Content) -> some View {

        content
            .frame(minWidth: 720, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
            .background(ComparisonModalSizingView(fillsWorkspace: true))

    }

}

extension View {

    func diffyDataModalFrame() -> some View {
        self.modifier(DiffyDataModalFrame())
    }

}
