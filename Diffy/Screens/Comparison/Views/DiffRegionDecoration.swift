import SwiftUI

struct DiffRegionDecoration: View {

    let region: DiffRegion
    let paneRatio: CGFloat
    let gutterWidth: CGFloat
    let lineHeight: CGFloat
    let showsTrailingLines: Bool
    let framesCurrentRegion: Bool
    @Environment(\.diffyTheme) private var theme

    private var guideColor: Color {

        switch self.region.status {

        case .modified: self.theme.changed
        case .added: self.theme.added
        case .removed: self.theme.removed
        default: self.theme.modified

        }

    }

    var body: some View {

        GeometryReader { geometry in

            let size = geometry.size
            let leftWidth = (size.width - self.gutterWidth) * self.paneRatio
            let rightOrigin = leftWidth + self.gutterWidth
            let rightWidth = size.width - rightOrigin

            if self.framesCurrentRegion {

                if self.region.status != .added {
                    regionFrame(width: leftWidth, height: size.height, innerEdge: .trailing)
                        .position(x: leftWidth / 2, y: size.height / 2)
                }

                if self.region.status != .removed {
                    regionFrame(width: rightWidth, height: size.height, innerEdge: .leading)
                        .position(x: rightOrigin + rightWidth / 2, y: size.height / 2)
                }

            }

            if self.showsTrailingLines {

                let frameInset: CGFloat = self.framesCurrentRegion ? 2 : 0

                connectorPath(size: size, leftEdge: leftWidth - frameInset, rightEdge: rightOrigin + frameInset)
                    .stroke(self.guideColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

            }

        }
        .allowsHitTesting(false)

    }

    private func regionFrame(width: CGFloat, height: CGFloat, innerEdge: Alignment) -> some View {

        RoundedRectangle(cornerRadius: 5)
            .stroke(self.guideColor.opacity(0.38), lineWidth: 1)
            .overlay(alignment: innerEdge) {
                self.guideColor.opacity(0.8).frame(width: 2)
            }
            .frame(width: max(0, width - 4), height: max(0, height - 3))

    }

    private func connectorPath(size: CGSize, leftEdge: CGFloat, rightEdge: CGFloat) -> Path {

        let difference = CGFloat(abs(self.region.updatedCount - self.region.originalCount))
        let offset = min(difference * self.lineHeight * 0.55, size.height * 0.7)
        let baseline = size.height - 2
        let leftY = baseline - (self.region.status == .added ? offset : 0)
        let rightY = baseline - (self.region.status == .removed ? offset : 0)
        let span = rightEdge - leftEdge

        var path = Path()
        path.move(to: CGPoint(x: leftEdge, y: leftY))
        path.addCurve(
            to: CGPoint(x: rightEdge, y: rightY),
            control1: CGPoint(x: leftEdge + span * 0.35, y: leftY),
            control2: CGPoint(x: rightEdge - span * 0.35, y: rightY)
        )

        return path

    }

}

#Preview {

    DiffRegionDecoration(
        region: MockPreviewFixtures.region,
        paneRatio: 0.5,
        gutterWidth: 44,
        lineHeight: 25,
        showsTrailingLines: true,
        framesCurrentRegion: true
    )
    .frame(width: 640, height: 130)
    .background(Color(hex: "202C3A"))
    .withMockPreviews()

}
