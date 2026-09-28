import SwiftUI

struct ReviewNoteCard: View {

    let annotation: CodeAnnotation
    @ObservedObject var workspace: WorkspaceViewModel
    let onEdit: () -> Void
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        let annotation = self.annotation

        return VStack(alignment: .leading, spacing: 11) {

            Button {
                self.workspace.revealAnnotation(annotation)
            } label: {

                VStack(alignment: .leading, spacing: 5) {

                    Text((annotation.filePath as NSString).lastPathComponent)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(self.theme.accent)
                    Text(annotation.filePath)
                        .font(.system(size: 9))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(2)
                    Text("\(annotation.side.rawValue) · L\(annotation.startLine)–\(annotation.endLine)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)

                }

            }
            .buttonStyle(.plain)

            Text(annotation.comment)
                .font(.system(size: 12))
                .lineSpacing(4)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            if annotation.priority == .important || annotation.priority == .urgent {
                DiffyBadge(title: annotation.priority?.title.uppercased() ?? "", color: self.theme.modified, size: .small)
            }

            if let criteria = annotation.acceptanceCriteria, !criteria.isEmpty {

                Text("Done when: \(criteria)")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

            }

            if let reason = annotation.needsReviewReason, annotation.needsReview {

                Label(reason.message, systemImage: "arrow.clockwise.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.modified)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Mark Reviewed") { self.review.markReviewed(annotation) }
                    .font(.system(size: 10))

                if let currentCode = currentCode(atSavedLinesFor: annotation) {

                    VStack(alignment: .leading, spacing: 5) {

                        Text("Current code at saved lines · location unverified")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(self.theme.secondaryText)
                        Text(currentCode.isEmpty ? "No code at these lines" : currentCode)
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)

                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 6))

                }

            }

            DisclosureGroup("Captured code") {

                Text(annotation.snippet)
                    .font(.system(size: 10, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 6))

            }
            .font(.system(size: 10))

            if annotation.side == .result {

                Text("Captured result snapshot · may differ from the current draft")
                    .font(.system(size: 9))
                    .foregroundStyle(self.theme.modified)

            }

            HStack {

                Button {

                    var updated = annotation
                    updated.isResolved.toggle()
                    self.review.update(updated)

                } label: {
                    Label(annotation.isResolved ? "Resolved" : "Resolve", systemImage: annotation.isResolved ? "checkmark.circle.fill" : "circle")
                }
                .foregroundStyle(annotation.isResolved ? self.theme.added : self.theme.secondaryText)

                Spacer()
                Button("Edit", action: self.onEdit)

                Button { self.review.remove(annotation) } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete Annotation")

            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundStyle(self.theme.secondaryText)

        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.theme.isDark ? self.theme.elevated : self.theme.surface, in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(self.theme.border.opacity(self.theme.isDark ? 0.65 : 1)))

    }

    private func currentCode(atSavedLinesFor annotation: CodeAnnotation) -> String? {

        guard annotation.projectID == self.workspace.selectedProjectID,
              let file = self.workspace.files.first(where: { $0.path == annotation.filePath || $0.originalPath == annotation.filePath }) else { return nil }

        return AnnotationSourceMatcher.currentSnippet(for: annotation, in: file)

    }

}
