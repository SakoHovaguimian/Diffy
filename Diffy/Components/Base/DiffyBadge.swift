import SwiftUI

struct DiffyBadge: View {

    let title: String
    let color: Color

    var body: some View {

        Text(self.title)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .foregroundStyle(self.color)
            .background(self.color.opacity(0.09), in: RoundedRectangle(cornerRadius: 5))

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
