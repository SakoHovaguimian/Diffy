import SwiftUI

struct DiffyBadge: View {

    let title: String
    let color: Color
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        Text(self.title)
            .font(self.contentSize.font(size: 10, weight: .medium))
            .padding(.horizontal, self.contentSize.scaled(7))
            .padding(.vertical, self.contentSize.scaled(4))
            .foregroundStyle(self.color)
            .background(self.color.opacity(0.09), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(5)))

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
