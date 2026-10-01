import SwiftUI

struct PullRequestPatchRow: View {

    let line: DiffLine
    let file: AIFileSnapshot
    let unified: Bool
    let canComment: Bool
    let comment: (Int, String) -> Void
    let note: ((Int, String, String) -> Void)?
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        Group {

            if self.unified {

                VStack(alignment: .leading, spacing: 0) {

                    if self.line.status == .identical {
                        code(self.line.right ?? self.line.left ?? "", number: self.line.newNumber, side: "RIGHT", marker: " ")
                    } else {

                        if let left = self.line.left {
                            code(left, number: self.line.oldNumber, side: "LEFT", marker: "−")
                        }
                        if let right = self.line.right {
                            code(right, number: self.line.newNumber, side: "RIGHT", marker: "+")
                        }

                    }

                }

            } else {

                HStack(alignment: .top, spacing: 0) {

                    code(self.line.left ?? "", number: self.line.oldNumber, side: "LEFT", marker: self.line.status == .identical ? " " : "−")
                        .frame(minWidth: 440, maxWidth: .infinity, alignment: .leading)
                    self.theme.border.frame(width: 1)
                    code(self.line.right ?? "", number: self.line.newNumber, side: "RIGHT", marker: self.line.status == .identical ? " " : "+")
                        .frame(minWidth: 440, maxWidth: .infinity, alignment: .leading)

                }

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(size: 12, design: .monospaced))

    }

    private func code(_ text: String, number: Int?, side: String, marker: String) -> some View {

        HStack(alignment: .top, spacing: 8) {

            DiffLineGutter(
                number: number,
                marker: "",
                markerColor: self.theme.secondaryText,
                selected: false,
                annotated: false,
                showsLineNumbers: true,
                lineHeight: 24,
                clipboardContent: number.map {
                    DiffLineClipboardContent(
                        filePath: side == "LEFT" ? self.file.previousFilename ?? self.file.filename : self.file.filename,
                        lineNumber: $0,
                        side: side == "LEFT" ? .left : .right,
                        source: text,
                        language: "text"
                    )
                },
                select: {},
                annotate: noteAction(number: number, side: side, text: text),
                annotationTitle: "Add Review Note On This Line",
                comment: commentAction(number: number, side: side)
            )
            Text(number == nil ? " " : marker).foregroundStyle(self.theme.secondaryText).frame(width: 10)
            Text(text.isEmpty ? " " : text).fixedSize(horizontal: true, vertical: true)
            Spacer(minLength: 12)

        }
        .padding(.vertical, 3)
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(number == nil || marker == " " ? Color.clear : (side == "LEFT" ? self.theme.removed : self.theme.added).opacity(0.10))

    }

    private func commentAction(number: Int?, side: String) -> (() -> Void)? {

        guard self.canComment, let number else { return nil }

        return {

            if self.line.status == .identical, let newNumber = self.line.newNumber {
                self.comment(newNumber, "RIGHT")
            } else {
                self.comment(number, side)
            }

        }

    }

    private func noteAction(number: Int?, side: String, text: String) -> (() -> Void)? {

        guard let note = self.note, let number else { return nil }
        return { note(number, side, text) }

    }

}
