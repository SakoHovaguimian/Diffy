import SwiftUI

struct FileNavigatorView: View {

    let files: [DiffFile]
    let mode: ComparisonMode
    let selectedFileID: String?
    let isLoading: Bool
    let isLive: Bool
    let selectFile: (DiffFile) -> Void
    var refresh: (() -> Void)? = nil
    var showFileHistory: ((DiffFile) -> Void)? = nil
    @ObservedObject var viewModel: FileNavigatorViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @State private var hoveredEntryID: String?

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            navigatorHeader()
            FileNavigatorSearchField(query: self.$viewModel.query)
            FileNavigatorOptions(viewModel: self.viewModel, files: self.files, mode: self.mode)

            if self.isLoading {

                DiffyLoadingState(title: "Reading Changed Files…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if self.files.isEmpty {

                DiffyEmptyState(symbol: "checkmark.circle", title: "No Changed Files", message: "Changes for this comparison will appear here.")

            } else if self.viewModel.entries(self.files, mode: self.mode).isEmpty {

                VStack(spacing: self.contentSize.scaled(12)) {

                    DiffyEmptyState(symbol: "line.3.horizontal.decrease.circle", title: "No Matching Files", message: "Try a different name or clear the active filters.")
                    Button("Clear Filters") { self.viewModel.clearFilters() }
                        .padding(.bottom, self.contentSize.scaled(24))

                }

            } else {

                ScrollView {

                    LazyVStack(spacing: self.contentSize.scaled(2)) {

                        ForEach(self.viewModel.entries(self.files, mode: self.mode)) { entry in
                            entryRow(entry)
                        }

                    }
                    .padding(.horizontal, self.contentSize.scaled(8))
                    .padding(.vertical, self.contentSize.scaled(12))

                }

            }

            Spacer(minLength: 0)
            navigatorFooter()

        }
        .background(self.theme.isDark ? self.theme.surface : self.theme.sidebar)

    }

    private func navigatorHeader() -> some View {

        HStack {

            Text("CHANGED FILES")
                .font(self.contentSize.font(size: 9, weight: .semibold))
                .tracking(self.contentSize.scaled(1.2))

            Spacer()

            Text("\(self.viewModel.visibleFiles(self.files, mode: self.mode).count)")
                .font(self.contentSize.font(size: 10, design: .monospaced))

            if let refresh {

                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(self.contentSize.font(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
                .help("Refresh Changed Files")
                .accessibilityLabel("Refresh Changed Files")
                .disabled(self.isLoading)

            }

        }
        .foregroundStyle(self.theme.secondaryText)
        .padding(.horizontal, self.contentSize.scaled(16))
        .padding(.top, self.contentSize.scaled(21))
        .padding(.bottom, self.contentSize.scaled(14))

    }

    @ViewBuilder
    private func entryRow(_ entry: FileTreeEntry) -> some View {

        if let file = entry.file {

            Button {
                self.selectFile(file)
            } label: {

                HStack(spacing: self.contentSize.scaled(9)) {

                    DiffFileIcon(file: file, size: 13)

                    Text(file.name)
                        .font(self.contentSize.font(size: 11))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: self.contentSize.scaled(3))

                    Image(systemName: file.status.symbol)
                        .font(self.contentSize.font(size: 9, weight: .bold))
                        .foregroundStyle(file.status.color(in: self.theme))
                        .frame(width: self.contentSize.scaled(18), height: self.contentSize.scaled(18))
                        .background(file.status.color(in: self.theme).opacity(0.12), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(4)))

                }
                .padding(.leading, self.contentSize.scaled(CGFloat(entry.depth) * 15 + 11))
                .padding(.trailing, self.contentSize.scaled(8))
                .padding(.vertical, self.contentSize.scaled(9))
                .background(
                    self.selectedFileID == file.id ? self.theme.selection :
                        self.hoveredEntryID == entry.id ? self.theme.elevated : .clear,
                    in: RoundedRectangle(cornerRadius: self.contentSize.scaled(8))
                )
                .overlay(alignment: .leading) {

                    if self.selectedFileID == file.id {

                        RoundedRectangle(cornerRadius: self.contentSize.scaled(2))
                            .fill(self.theme.accent)
                            .frame(width: self.contentSize.scaled(3))

                    }

                }
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .onHover { hovering in self.hoveredEntryID = hovering ? entry.id : nil }
            .help(file.lastEditedAt == nil ? "\(file.path) · \(file.status.rawValue)" : "\(file.path) · \(file.status.rawValue) · edited \(file.updatedMinutesAgo)m ago")
            .accessibilityLabel("\(file.path), \(file.status.rawValue)")
            .contextMenu {

                Button("Open Comparison") { self.selectFile(file) }
                Button("Copy Relative Path") { ExportController.copy(file.path) }
                if let showFileHistory {
                    Button("Show File History") { showFileHistory(file) }
                }

            }

        } else {

            FileNavigatorGroupRow(entry: entry, viewModel: self.viewModel)
        }

    }

    private func navigatorFooter() -> some View {

        VStack(alignment: .leading, spacing: self.contentSize.scaled(6)) {

            Label(self.viewModel.sort.displayName, systemImage: "arrow.up.arrow.down")

            if let filter = self.viewModel.filter {
                Text("Showing \(filter.rawValue.lowercased()) files")
            }

            Text(self.isLive ? "Dates show last edit on disk when available" : "Dates are fixed sample metadata")
                .font(self.contentSize.font(size: 9))

        }
        .font(self.contentSize.font(size: 10))
        .foregroundStyle(self.theme.secondaryText)
        .padding(self.contentSize.scaled(14))

    }

}
