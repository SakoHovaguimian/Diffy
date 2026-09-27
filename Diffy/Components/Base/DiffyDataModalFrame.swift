import SwiftUI

private struct DiffyDataModalFrame: ViewModifier {

    @Environment(\.diffyDataModalSize) private var workspaceSize

    func body(content: Content) -> some View {

        content
            .frame(minWidth: 720, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
            .frame(
                width: self.workspaceSize.width > 0 ? self.workspaceSize.width : nil,
                height: self.workspaceSize.height > 0 ? self.workspaceSize.height : nil
            )
            .background(ComparisonModalSizingView(fillsWorkspace: true))

    }

}

extension View {

    func diffyDataModalFrame() -> some View {
        self.modifier(DiffyDataModalFrame())
    }

}
