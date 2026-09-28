import SwiftUI

struct FileNavigationSettingsSection: View {

    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {

        Section {

            Picker("Default Layout", selection: self.$viewModel.fileNavigationDefaults.layout) {

                Text("Use Each Screen's Default").tag(nil as FileListLayout?)
                ForEach(FileListLayout.allCases) { layout in
                    Text(layout.displayName).tag(Optional(layout))
                }

            }

            Picker("Default Sort", selection: self.$viewModel.fileNavigationDefaults.sort) {
                ForEach(FileSortOrder.allCases) { order in
                    Text(order.displayName).tag(order)
                }
            }

        } header: {
            Label("Default File Tree View", systemImage: "sidebar.left")
        } footer: {
            Text("Sets the starting layout and sort for changed files. You can change either from the file tree while browsing. Each screen's default keeps Folder Tree for comparisons and pull requests, and Flat List for expanded reviews. Pull requests use File Structure when a sort needs local file dates or sizes.")
        }

    }

}
