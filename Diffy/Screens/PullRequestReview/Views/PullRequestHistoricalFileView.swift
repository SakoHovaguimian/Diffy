import SwiftUI

struct PullRequestHistoricalFileView: View {

    let selection: PullRequestHistoricalFileSelection
    let close: () -> Void
    @Environment(\.diffyTheme) private var theme

    private var lines: [DiffLine] {
        self.selection.file.patch.map(GitPatchParser.unifiedLines) ?? []
    }

    var body: some View {

        VStack(spacing: 0) {

            HStack(alignment: .top, spacing: 14) {

                VStack(alignment: .leading, spacing: 8) {

                    Label(self.selection.isCurrentRevision ? "Captured Full Diff" : "Historical Diff", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(self.theme.accent)
                    Text(self.selection.file.filename)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .textSelection(.enabled)
                    Text("Captured \(self.selection.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(String(self.selection.headSHA.prefix(7)))")
                        .font(.system(size: 11))
                        .foregroundStyle(self.theme.secondaryText)

                }
                Spacer()
                Button("Return To Current Files") { self.close() }

            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(self.theme.surface)
            .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

            ScrollView([.horizontal, .vertical]) {

                if self.lines.isEmpty {

                    if let patch = self.selection.file.patch, !patch.isEmpty {
                        Text(patch)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(20)
                    } else {
                        DiffyStatusBanner(message: "The analysis did not capture a diff for this file.")
                            .padding(20)
                    }

                } else {

                    LazyVStack(alignment: .leading, spacing: 0) {

                        ForEach(self.lines) { line in
                            PullRequestPatchRow(line: line, unified: true, canComment: false, comment: { _, _ in }, note: nil)
                        }

                    }
                    .textSelection(.enabled)
                    .padding(16)

                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        }

    }
}
