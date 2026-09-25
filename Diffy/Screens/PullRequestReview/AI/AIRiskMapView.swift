import SwiftUI

struct AIRiskMapView: View {

    let response: RiskMapResponse
    let generation: AIReviewGeneration
    let onOpenFile: (AIReviewGeneration, String) -> Void
    @Binding var selectedRiskID: String?
    @Binding var selectedFilePath: String?
    @Binding var fileFilter: RiskAttention?
    @Environment(\.diffyTheme) private var theme

    private var selectedRisk: RiskItem? {
        self.response.risks.first { $0.id == self.selectedRiskID }
    }

    private var selectedFile: RiskFileAssessment? {
        let visible = (self.response.fileAssessments ?? [])
            .filter { self.fileFilter == nil || $0.attention == self.fileFilter }
            .sorted {
                if $0.attention != $1.attention { return $0.attention.sortOrder < $1.attention.sortOrder }
                return $0.path.localizedStandardCompare($1.path) == .orderedAscending
            }
        return visible.first { $0.path == self.selectedFilePath } ?? visible.first
    }

    var body: some View {

        GeometryReader { geometry in

            if geometry.size.width >= 900 {

                HStack(spacing: 0) {

                    ScrollView {
                        mainContent()
                            .padding(24)
                    }
                    .frame(maxWidth: .infinity)
                    self.theme.border.frame(width: 1)
                    inspector()
                        .frame(width: 360)

                }

            } else {

                ScrollView {

                    VStack(alignment: .leading, spacing: 20) {

                        mainContent()
                        inspector()
                            .frame(height: 420)

                    }
                    .padding(20)

                }

            }

        }

    }

    private func mainContent() -> some View {

        VStack(alignment: .leading, spacing: 20) {

            AIRiskMapSummaryView(response: self.response, totalFiles: self.generation.context.fileInventory.count)
            AIRiskFileListView(
                assessments: self.response.fileAssessments,
                generation: self.generation,
                selectedPath: self.selectedRisk == nil ? self.selectedFile?.path : nil,
                filter: self.$fileFilter,
                select: { path in
                    self.selectedFilePath = path
                    self.selectedRiskID = nil
                },
                openDiff: { self.onOpenFile(self.generation, $0) }
            )
            AIRiskAreaListView(
                risks: self.response.risks,
                selectedID: self.selectedRisk?.id,
                select: { id in
                    self.selectedRiskID = id
                    self.selectedFilePath = nil
                },
                openDiff: { self.onOpenFile(self.generation, $0) }
            )

        }

    }

    private func inspector() -> some View {

        AIRiskInspectorView(
            file: self.selectedRisk == nil ? self.selectedFile : nil,
            risk: self.selectedRisk,
            generation: self.generation,
            openDiff: { self.onOpenFile(self.generation, $0) }
        )

    }

}

extension RiskAttention {

    var title: String {

        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }

    }

    func color(in theme: DiffyTheme) -> Color {

        switch self {
        case .high: theme.removed
        case .medium: theme.modified
        case .low: theme.changed
        }

    }

    var sortOrder: Int {

        switch self {
        case .high: 0
        case .medium: 1
        case .low: 2
        }

    }

}

extension RiskConfidence {

    var title: String {

        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }

    }

}
