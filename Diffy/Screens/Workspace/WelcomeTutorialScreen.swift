import SwiftUI

struct WelcomeTutorialScreen: View {

    let onContinue: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 31, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.22, green: 0.54, blue: 0.98), Color(red: 0.49, green: 0.31, blue: 0.84)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .padding(.bottom, 20)

            Text("Welcome to Diffy")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(self.theme.text)

            Text("Understand changes, capture decisions, and move forward with confidence.")
                .font(.system(size: 14))
                .foregroundStyle(self.theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 7)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 18) {

                ForEach(TutorialFeature.essentials) { feature in
                    featureRow(feature)
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Get Started", action: self.onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
                .keyboardShortcut(.defaultAction)

            Text("Start with a local project. GitHub and AI are optional.")
                .font(.system(size: 11))
                .foregroundStyle(self.theme.secondaryText)
                .padding(.top, 10)

        }
        .padding(.horizontal, 54)
        .padding(.vertical, 30)
        .frame(width: 650)
        .background(self.theme.background)

    }

    private func featureRow(_ feature: TutorialFeature) -> some View {

        HStack(alignment: .center, spacing: 17) {

            Image(systemName: feature.symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 51, height: 51)
                .background(
                    LinearGradient(colors: feature.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 13)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {

                Text(feature.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(self.theme.text)
                Text(feature.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

            }
            .frame(maxWidth: .infinity, alignment: .leading)

        }
        .accessibilityElement(children: .combine)

    }

}

#Preview {
    WelcomeTutorialScreen(onContinue: {})
        .withMockPreviews()
}
