import SwiftUI

struct WorkspaceFocusedKey: FocusedValueKey {

    typealias Value = WorkspaceViewModel

}

extension FocusedValues {

    var workspace: WorkspaceViewModel? {

        get { self[WorkspaceFocusedKey.self] }
        set { self[WorkspaceFocusedKey.self] = newValue }

    }

}

struct DiffyCommands: Commands {

    @FocusedValue(\.workspace) private var workspace

    var body: some Commands {

        CommandGroup(after: .newItem) {

            Button("New Bucket") {
                self.workspace?.addBucket()
            }
            .keyboardShortcut("b", modifiers: [.command, .shift])

        }

        CommandMenu("Compare") {

            ForEach(ComparisonMode.allCases) { mode in

                Button(mode.rawValue) {
                    self.workspace?.selectMode(mode)
                }

            }

        }

        CommandMenu("Review") {

            Button("Show Review Notes") {
                self.workspace?.showsReview.toggle()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Button("Command Palette") {
                self.workspace?.showsCommandPalette = true
            }
            .keyboardShortcut("k", modifiers: .command)

        }

        CommandGroup(after: .sidebar) {

            Button("Toggle Project Sidebar") {
                self.workspace?.showsSidebar.toggle()
            }
            .keyboardShortcut("s", modifiers: [.command, .control])

        }

    }

}
