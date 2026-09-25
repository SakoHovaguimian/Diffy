import SwiftUI

struct PullRequestPatchRow: View {

    let line: DiffLine
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

            Button {
                if self.line.status == .identical, let newNumber = self.line.newNumber {
                    self.comment(newNumber, "RIGHT")
                } else if let number {
                    self.comment(number, side)
                }
            } label: {
                Image(systemName: "plus.bubble").font(.system(size: 11)).frame(width: 22)
            }
            .buttonStyle(.plain)
            .foregroundStyle(self.theme.accent)
            .disabled(!self.canComment || number == nil)
            .accessibilityLabel("Comment On \(side == "LEFT" ? "Old" : "New") Line \(number ?? 0)")
            if let note, let number {

                Button {
                    note(number, side, text)
                } label: {
                    Image(systemName: "square.and.pencil").font(.system(size: 11)).frame(width: 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(self.theme.accent)
                .accessibilityLabel("Add Review Note On \(side == "LEFT" ? "Old" : "New") Line \(number)")

            }
            Text(number.map(String.init) ?? "").foregroundStyle(self.theme.secondaryText).frame(width: 42, alignment: .trailing)
            Text(number == nil ? " " : marker).foregroundStyle(self.theme.secondaryText).frame(width: 10)
            Text(text.isEmpty ? " " : text).fixedSize(horizontal: true, vertical: true)
            Spacer(minLength: 12)

        }
        .padding(.vertical, 3)
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(number == nil || marker == " " ? Color.clear : (side == "LEFT" ? self.theme.removed : self.theme.added).opacity(0.10))

    }

}
