import SwiftUI

struct EditAnnotationScreen: View {

    @State var annotation: CodeAnnotation
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Edit annotation").font(.title2.weight(.semibold))
            Text(self.annotation.filePath).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: self.$annotation.comment)
                .font(.body)
                .frame(height: 180)

            HStack {

                Spacer()
                Button("Cancel") { self.dismiss() }.keyboardShortcut(.cancelAction)

                Button("Save") {

                    self.review.update(self.annotation)
                    self.dismiss()

                }
                .keyboardShortcut(.defaultAction)
                .disabled(self.annotation.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(24)
        .frame(width: 510)

    }

}

#Preview {

    EditAnnotationScreen(
        annotation: MockPreviewFixtures.annotation
    )
    .withMockPreviews()

}
