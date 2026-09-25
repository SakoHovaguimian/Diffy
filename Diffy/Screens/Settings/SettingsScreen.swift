import SwiftUI

struct SettingsScreen: View {

    @EnvironmentObject private var viewModel: SettingsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        TabView {

            GitHubAccountsScreen()
                .tabItem { Label("Accounts", systemImage: "person.crop.circle") }

            AISettingsScreen(viewModel: self.viewModel.ai)
                .tabItem { Label("AI Review", systemImage: "sparkles") }

            AppearanceSettingsScreen()
                .tabItem { Label("Appearance", systemImage: "paintpalette") }

            editorSettings()
                .tabItem { Label("Editor", systemImage: "textformat") }

            comparisonSettings()
                .tabItem { Label("Comparison", systemImage: "rectangle.split.2x1") }

            shortcutSettings()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }

            repositorySettings()
                .tabItem { Label("Repository", systemImage: "folder") }

        }
        .padding(12)
        .frame(width: 780, height: 680)

    }

    private func editorSettings() -> some View {

        Form {

            Section("Typography") {

                Picker("Font Family", selection: self.$viewModel.editor.fontName) {
                    ForEach(["SF Mono", "Geist Mono", "Menlo", "Monaco", "Courier"], id: \.self) { Text($0).tag($0) }
                }

                Slider(value: self.$viewModel.editor.fontSize, in: 9...20, step: 1) {
                    Text("Font Size · \(Int(self.viewModel.editor.fontSize)) pt")
                }

                Slider(value: self.$viewModel.editor.lineHeight, in: 20...38, step: 1) {
                    Text("Line Height · \(Int(self.viewModel.editor.lineHeight)) pt")
                }

            }

            Section("Reading") {

                Toggle("Wrap Long Lines", isOn: self.$viewModel.editor.wrapLines)
                Toggle("Show Line Numbers", isOn: self.$viewModel.editor.showLineNumbers)
                Toggle("Visualize Spaces", isOn: self.$viewModel.editor.showWhitespace)

            }

            Section {

                Text("func makeRoomForTheDetails() {\n\n    return .somethingBeautiful\n\n}")
                    .font(.custom(self.viewModel.editor.fontName == "SF Mono" ? "Menlo" : self.viewModel.editor.fontName, size: self.viewModel.editor.fontSize))
                    .lineSpacing(max(0, self.viewModel.editor.lineHeight - 20))
                    .foregroundStyle(self.theme.keyword)
                    .padding(.vertical, 10)

            }

            Button("Reset Editor Settings") { self.viewModel.resetEditor() }

        }
        .formStyle(.grouped)

    }

    private func comparisonSettings() -> some View {

        Form {

            Section("Presentation") {

                Toggle("Use Unified Comparison", isOn: self.$viewModel.editor.unified)
                Toggle("Collapse Unchanged Regions", isOn: self.$viewModel.editor.collapseUnchanged)
                Stepper("Context Lines: \(self.viewModel.editor.contextLines)", value: self.$viewModel.editor.contextLines, in: 0...12)

                Picker("Inline Highlighting", selection: self.$viewModel.editor.highlightLevel) {
                    ForEach(["Line", "Word", "Character"], id: \.self) { Text($0).tag($0) }
                }
                Text("Word and Character emphasize changed text within paired lines. Added and removed lines keep their full-line shading.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Section("Diff Visualization") {

                Toggle("Show Diff Trailing Lines", isOn: self.$viewModel.diffVisualization.showsTrailingLines)
                Toggle("Frame Current Diff Regions", isOn: self.$viewModel.diffVisualization.framesCurrentRegion)
                Text("In split view, red and green guides connect the previous source to each changed region. Guides adjust to each region's length and position.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Section("Prototype Display Rules") {

                Toggle("Hide Comment-Only Rows", isOn: self.$viewModel.editor.ignoreComments)
                Text("Comment hiding affects rows in the preview; it is not a language-aware comparison algorithm.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Section("Engine Controls · Later Milestones") {

                Label("Ignore Whitespace, Indentation & Formatting", systemImage: "clock")
                Label("Diff Algorithms & Moved-Block Detection", systemImage: "clock")
                Text("The prototype uses immutable, aligned comparison fixtures. These controls will become active when the corresponding engine is implemented.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

        }
        .formStyle(.grouped)

    }

    private func shortcutSettings() -> some View {

        Form {

            Section("Workspace") {

                shortcut("Command Palette", keys: "⌘ K")
                shortcut("Review Notes", keys: "⇧ ⌘ R")
                shortcut("New Bucket", keys: "⇧ ⌘ B")
                shortcut("Toggle Sidebar", keys: "⌃ ⌘ S")
                shortcut("Settings", keys: "⌘ ,")
                shortcut("New Window", keys: "⌘ N")

            }

            Section("Review") {

                shortcut("Select A Range", keys: "Shift + Click")
                shortcut("Annotate A Line", keys: "Right-Click → Annotate")
                shortcut("Save Annotation", keys: "Return")
                shortcut("Dismiss A Sheet", keys: "Esc")

            }

            Text("Shortcut remapping and collision feedback are planned for the remaining Milestone 0 polish pass.")
                .font(.caption)
                .foregroundStyle(.secondary)

        }
        .formStyle(.grouped)

    }

    private func shortcut(_ title: String, keys: String) -> some View {

        HStack {

            Text(title)
            Spacer()
            Text(keys).font(.system(size: 11, design: .monospaced)).foregroundStyle(self.theme.secondaryText)

        }

    }

    private func repositorySettings() -> some View {

        Form {

            Section("Local By Design") {

                Label("Local repositories work without a GitHub account", systemImage: "folder")
                Label("Review notes are saved on this Mac", systemImage: "internaldrive")
                Label("Git actions use your Mac’s existing credentials", systemImage: "checkmark.shield")

            }

            Section("Storage") {

                Text("Review notes: ~/Library/Application Support/Diffy/annotations-v1.json")
                    .textSelection(.enabled)
                    .font(.system(size: 11, design: .monospaced))
                Text("Appearance, editor settings, and demo Bucket customizations use local preferences.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Section("Git & GitHub") {

                Text("Connect GitHub in Accounts. The Live app uses /usr/bin/git, your repository’s author identity, SSH agent, and credential helper. Install the Command Line Tools if Git is unavailable. The Mock app keeps its sample sources immutable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

        }
        .formStyle(.grouped)

    }

}

#Preview {

    SettingsScreen()
    .withMockPreviews()

}
