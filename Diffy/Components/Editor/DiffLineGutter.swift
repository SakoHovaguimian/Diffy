import SwiftUI

struct DiffLineGutter: View {

    let number: Int?
    let marker: String
    let markerColor: Color
    let selected: Bool
    let annotated: Bool
    let showsLineNumbers: Bool
    let lineHeight: CGFloat
    let clipboardContent: DiffLineClipboardContent?
    let select: () -> Void
    let annotate: (() -> Void)?
    let annotationTitle: String
    let comment: (() -> Void)?
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @State private var isHovering = false
    @State private var didCopy = false

    static func width(showsLineNumbers: Bool, hasComment: Bool) -> CGFloat {
        showsLineNumbers ? 96 + (hasComment ? 22 : 0) : 20
    }

    var body: some View {

        HStack(spacing: self.contentSize.scaled(4)) {

            markerView()
                .contentShape(Rectangle())
                .onTapGesture(perform: self.select)

            if self.showsLineNumbers {

                Text(self.number.map(String.init) ?? "")
                    .font(self.contentSize.font(size: 10, design: .monospaced))
                    .foregroundStyle(self.selected ? self.theme.accent : self.theme.secondaryText)
                    .frame(width: self.contentSize.scaled(30), alignment: .trailing)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: self.select)

                if self.number != nil {
                    hoverActions()
                        .opacity(self.isHovering ? 1 : 0)
                        .allowsHitTesting(self.isHovering)
                        .accessibilityHidden(!self.isHovering)
                }

            }

        }
        .frame(
            width: self.contentSize.scaled(Self.width(showsLineNumbers: self.showsLineNumbers, hasComment: self.comment != nil)),
            height: self.contentSize.scaled(self.lineHeight)
        )
        .padding(.trailing, self.contentSize.scaled(8))
        .contentShape(Rectangle())
        .onHover { hovering in

            self.isHovering = hovering
            if !hovering { self.didCopy = false }

        }
        .contextMenu {
            lineActions()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(self.number.map { "Line \($0)" } ?? "Empty Line")
        .accessibilityActions {
            lineActions()
        }

    }

    private func markerView() -> some View {

        Group {

            if self.annotated {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(self.theme.accent)
                    .font(self.contentSize.font(size: 8))
            } else {
                Text(self.marker)
                    .foregroundStyle(self.markerColor)
                    .font(self.contentSize.font(size: 10, design: .monospaced))
            }

        }
        .frame(width: self.contentSize.scaled(10))

    }

    private func hoverActions() -> some View {

        HStack(spacing: self.contentSize.scaled(4)) {

            if let comment {
                actionButton(symbol: "plus.bubble", title: "Comment On This Line", action: comment)
            }

            if let annotate {
                actionButton(symbol: "square.and.pencil", title: self.annotationTitle, action: annotate)
            }

            if self.clipboardContent != nil {

                actionButton(
                    symbol: self.didCopy ? "checkmark" : "clipboard",
                    title: self.didCopy ? "Copied Line With Context" : "Copy Line With File & Line Number",
                    color: self.didCopy ? self.theme.added : self.theme.secondaryText,
                    action: copyLine
                )

            }

        }

    }

    private func actionButton(
        symbol: String,
        title: String,
        color: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            Image(systemName: symbol)
                .font(self.contentSize.font(size: 11))
                .frame(width: self.contentSize.scaled(18), height: self.contentSize.scaled(self.lineHeight))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(color ?? self.theme.secondaryText)
        .accessibilityLabel(title)
        .help(title)

    }

    @ViewBuilder
    private func lineActions() -> some View {

        if self.number != nil {

            if let comment {
                Button("Comment On This Line", action: comment)
            }

            if let annotate {
                Button(self.annotationTitle, action: annotate)
            }

            if self.clipboardContent != nil {
                Button("Copy Line With File & Line Number", action: copyLine)
            }

        }

    }

    private func copyLine() {

        guard let clipboardContent = self.clipboardContent else { return }
        self.didCopy = ExportController.copy(clipboardContent.markdown)

    }

}
