import SwiftUI

struct WorkspaceSidebarPane: View {

    @ObservedObject var viewModel: WorkspaceViewModel
    let isOperating: Bool
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var widthDuringDrag: Double?
    @State private var dragStartWidth: Double?

    var body: some View {

        HStack(spacing: 0) {

            WorkspaceSidebar(viewModel: self.viewModel)
                .disabled(self.isOperating)
                .frame(width: self.widthDuringDrag ?? max(214, self.settings.appearance.sidebarWidth))

            HorizontalResizeHandle(label: "Drag To Resize Sidebar", resizeGesture: resizeGesture())

        }

    }

    private func resizeGesture() -> some Gesture {

        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in

                if self.dragStartWidth == nil {
                    self.dragStartWidth = self.settings.appearance.sidebarWidth
                }

                let startingWidth = self.dragStartWidth ?? self.settings.appearance.sidebarWidth
                self.widthDuringDrag = min(320, max(214, startingWidth + value.translation.width))

            }
            .onEnded { _ in

                if let widthDuringDrag = self.widthDuringDrag {
                    self.settings.appearance.sidebarWidth = widthDuringDrag
                }

                self.widthDuringDrag = nil
                self.dragStartWidth = nil

            }

    }

}
