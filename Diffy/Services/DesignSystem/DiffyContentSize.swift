import SwiftUI

struct DiffyContentSize: Equatable {

    let scale: CGFloat

    init(scale: Double) {
        self.scale = CGFloat(scale)
    }

    func scaled(_ value: CGFloat) -> CGFloat {
        value * self.scale
    }

    func font(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {

        .system(
            size: scaled(size),
            weight: weight,
            design: design
        )

    }

}

private struct DiffyContentSizeKey: EnvironmentKey {
    static let defaultValue = DiffyContentSize(scale: 1)
}

extension EnvironmentValues {

    var diffyContentSize: DiffyContentSize {
        get { self[DiffyContentSizeKey.self] }
        set { self[DiffyContentSizeKey.self] = newValue }
    }

}

struct DiffyContentSizeModifier: @MainActor AnimatableModifier {

    var scale: Double

    var animatableData: Double {
        get { self.scale }
        set { self.scale = newValue }
    }

    func body(content: Content) -> some View {
        content.environment(\.diffyContentSize, DiffyContentSize(scale: self.scale))
    }

}

extension View {

    func diffyContentSize(_ scale: Double) -> some View {
        self.modifier(DiffyContentSizeModifier(scale: scale))
    }

}
