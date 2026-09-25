import SwiftUI

struct DiffFileIcon: View {

    let file: DiffFile
    var size: CGFloat = 12
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var symbol: String {

        switch (self.file.path as NSString).pathExtension.lowercased() {

        case "swift": "swift"
        case "ts", "tsx": "curlybraces"
        case "md", "markdown": "text.alignleft"
        case "png", "jpg", "jpeg", "webp": "photo"
        case "json": "curlybraces.square"
        case "woff", "woff2": "textformat"
        default: self.file.kind == .binary ? "doc.zipper" : "doc.text"

        }

    }

    private var color: Color {

        switch (self.file.path as NSString).pathExtension.lowercased() {

        case "swift": Color(hex: "E88A5B")
        case "ts", "tsx": Color(hex: "5C9FEB")
        case "md", "markdown": Color(hex: "A88BE8")
        case "png", "jpg", "jpeg", "webp": Color(hex: "56BFA4")
        case "json": Color(hex: "D9AE5F")
        case "woff", "woff2": Color(hex: "D986AF")
        default: self.theme.secondaryText

        }

    }

    var body: some View {

        Image(systemName: self.symbol)
            .font(self.contentSize.font(size: self.size, weight: .medium))
            .foregroundStyle(self.color)
            .frame(width: self.contentSize.scaled(self.size + 6))
            .accessibilityHidden(true)

    }

}

#Preview {

    HStack(spacing: 20) {

        DiffFileIcon(file: MockPreviewFixtures.textFile, size: 20)
        DiffFileIcon(file: MockPreviewFixtures.imageFile, size: 20)
        DiffFileIcon(file: MockWorkspaceFixtures.projects[4].files[0], size: 20)

    }
    .padding(24)
    .withMockPreviews()

}
