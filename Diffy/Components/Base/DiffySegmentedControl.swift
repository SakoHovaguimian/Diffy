import SwiftUI

struct DiffySegmentedControl<Selection: Hashable>: View {

    let title: String
    let options: [Selection]
    @Binding var selection: Selection
    let label: (Selection) -> String
    @Namespace private var selectionNamespace
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {

        HStack(spacing: self.contentSize.scaled(2)) {
            ForEach(self.options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(self.contentSize.scaled(4))
        .background(self.theme.background, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(10)))
        .overlay {
            RoundedRectangle(cornerRadius: self.contentSize.scaled(10))
                .stroke(self.theme.border, lineWidth: 1)
        }
        .animation(self.reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.88), value: self.selection)
        .opacity(self.isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(self.title)

    }

    private func segment(_ option: Selection) -> some View {

        Button {
            self.selection = option
        } label: {

            Text(self.label(option))
                .font(self.contentSize.font(size: 11, weight: .medium))
                .foregroundStyle(self.selection == option ? self.theme.text : self.theme.secondaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, self.contentSize.scaled(10))
                .padding(.vertical, self.contentSize.scaled(7))
                .background {

                    if self.selection == option {

                        RoundedRectangle(cornerRadius: self.contentSize.scaled(7))
                            .fill(self.theme.elevated)
                            .overlay {
                                RoundedRectangle(cornerRadius: self.contentSize.scaled(7))
                                    .stroke(self.theme.accent.opacity(0.35), lineWidth: 1)
                            }
                            .matchedGeometryEffect(id: "selection", in: self.selectionNamespace)

                    }

                }
                .contentShape(RoundedRectangle(cornerRadius: self.contentSize.scaled(7)))

        }
        .buttonStyle(.plain)
        .accessibilityLabel(self.label(option))
        .accessibilityAddTraits(self.selection == option ? .isSelected : [])

    }

}
