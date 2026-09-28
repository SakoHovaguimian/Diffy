import SwiftUI

struct TutorialSettingsBanner: View {

    let showTutorial: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(spacing: 15) {

            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 47, height: 47)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.53, blue: 0.96), Color(red: 0.53, green: 0.32, blue: 0.83)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 3) {

                Text("Get more from Diffy")
                    .font(.system(size: 14, weight: .semibold))
                Text("Revisit the essentials whenever you need a refresher.")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }

            Spacer()

            Button("View Tutorial", action: self.showTutorial)
                .buttonStyle(.borderedProminent)

        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [self.theme.accent.opacity(0.13), self.theme.elevated],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 13)
        )
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(self.theme.border.opacity(0.75)))

    }

}
