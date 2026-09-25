import SwiftUI

struct DiffyBadge: View {

    enum Size: Equatable {
        case regular
        case small
    }

    let title: String
    let color: Color
    let size: Size
    @Environment(\.diffyContentSize) private var contentSize

    init(
        title: String,
        color: Color,
        size: Size = .regular
    ) {

        self.title = title
        self.color = color
        self.size = size

    }

    var body: some View {

        Text(self.title)
            .font(self.contentSize.font(size: self.fontSize, weight: .medium))
            .padding(.horizontal, self.contentSize.scaled(self.horizontalPadding))
            .padding(.vertical, self.contentSize.scaled(self.verticalPadding))
            .foregroundStyle(self.color)
            .background(self.color.opacity(0.09), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(self.cornerRadius)))

    }

    private var fontSize: CGFloat {
        self.size == .small ? 9 : 10
    }

    private var horizontalPadding: CGFloat {
        self.size == .small ? 6 : 7
    }

    private var verticalPadding: CGFloat {
        self.size == .small ? 2 : 4
    }

    private var cornerRadius: CGFloat {
        self.size == .small ? 4 : 5
    }

}

#Preview {

    DiffyBadge(
        title: "SAMPLE",
        color: Color(hex: "7862D9")
    )
    .padding(24)
    .withMockPreviews()

}
