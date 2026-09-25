import SwiftUI

struct AIReviewGenerationHeader: View {

    let generation: AIReviewGeneration
    let revisionStatus: AIReviewRevisionStatus
    let isGenerating: Bool
    let regenerate: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 11) {

            HStack(alignment: .firstTextBaseline, spacing: 12) {

                Text(self.generation.visualizationType.title)
                    .font(.system(size: 18, weight: .semibold))
                Spacer(minLength: 8)
                Text(self.generation.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }
            HStack(spacing: 8) {

                DiffyBadge(title: self.generation.provider.title, color: self.theme.accent, size: .small)
                Text(self.generation.model)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)
                Text("·")
                    .foregroundStyle(self.theme.secondaryText)
                Text(self.generation.route.title)
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
                Spacer(minLength: 8)
                Text("\(String(self.generation.baseSHA.prefix(7))) → \(String(self.generation.headSHA.prefix(7)))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)

            }
            if !self.generation.context.omissions.isEmpty {

                DisclosureGroup("Context Limits") {

                    ForEach(self.generation.context.omissions, id: \.self) { omission in
                        Text(omission)
                            .font(.system(size: 11))
                            .foregroundStyle(self.theme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
                .font(.system(size: 11, weight: .medium))

            }
            if case .outdated = self.revisionStatus {

                HStack(spacing: 12) {

                    Label("Analyzed Before The Latest PR Changes", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(self.theme.modified)
                    Spacer(minLength: 8)
                    Button("Regenerate For Latest Changes", action: self.regenerate)
                        .disabled(self.isGenerating)

                }
                .padding(10)
                .background(self.theme.modified.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            }
            if case .unknown = self.revisionStatus {
                DiffyStatusBanner(message: "Current PR revision unavailable. This review belongs to the saved base and head revisions.")
            }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

}
