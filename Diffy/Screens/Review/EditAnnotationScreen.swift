import SwiftUI

struct EditAnnotationScreen: View {

    @State var annotation: CodeAnnotation
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Edit Annotation").font(.title2.weight(.semibold))
            Text(self.annotation.filePath).font(.caption).foregroundStyle(.secondary)
            TextEditor(text: self.$annotation.comment)
                .font(.body)
                .frame(height: 180)

            Picker("Priority", selection: Binding(
                get: { self.annotation.priority ?? .normal },
                set: { self.annotation.priority = $0 }
            )) {
                ForEach(AnnotationPriority.allCases) { priority in
                    Text(priority.title).tag(priority)
                }
            }

            TextField("Done when… (optional)", text: Binding(
                get: { self.annotation.acceptanceCriteria ?? "" },
                set: {

                    let text = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.annotation.acceptanceCriteria = text.isEmpty ? nil : text

                }
            ))

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
