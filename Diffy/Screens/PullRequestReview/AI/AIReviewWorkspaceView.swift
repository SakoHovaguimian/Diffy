import SwiftUI

struct AIReviewWorkspaceView: View {

    @ObservedObject var viewModel: AIReviewWorkspaceViewModel
    let visualization: AIVisualization
    let onOpenFile: (AIReviewGeneration, String) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(spacing: 0) {

            mainContent()
            self.theme.border.frame(width: 1)
            AIReviewHistoryView(viewModel: self.viewModel, visualization: self.visualization)
                .frame(width: 250)

        }
        .background(self.theme.background)

    }

    @ViewBuilder
    private func mainContent() -> some View {

        if let generation = self.viewModel.activeGeneration(for: self.visualization) {

            VStack(spacing: 0) {

                AIReviewGenerationHeader(
                    generation: generation,
                    revisionStatus: self.viewModel.revisionStatus(for: generation),
                    isGenerating: self.viewModel.isGenerating,
                    regenerate: { self.viewModel.regenerate(visualization: self.visualization) }
                )
                if let message = self.viewModel.errorMessage {
                    DiffyStatusBanner(message: message, isError: true)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }
                if let message = self.viewModel.persistenceMessage {

                    HStack {

                        DiffyStatusBanner(message: message, isError: true)
                        if !self.viewModel.unsavedGenerations.isEmpty {
                            Button("Retry Saving Reviews") { self.viewModel.retrySaveGeneration() }
                        } else {
                            Button("Retry Loading History") { self.viewModel.retryLoadingHistory() }
                        }

                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                }
                resultContent(generation)

            }

        } else {

            VStack(spacing: 0) {

                if let message = self.viewModel.persistenceMessage {

                    HStack {

                        DiffyStatusBanner(message: message, isError: true)
                        Button("Retry Loading History") { self.viewModel.retryLoadingHistory() }

                    }
                    .padding(16)

                }
                AIReviewEmptyView(
                    visualization: self.visualization,
                    isGenerating: self.viewModel.isGenerating,
                    generate: { self.viewModel.openComposer(for: self.visualization) }
                )

            }

        }

    }

    @ViewBuilder
    private func resultContent(_ generation: AIReviewGeneration) -> some View {

        switch generation.structuredOutput {

        case .learningPath(let response):
            AILearningPathView(
                response: response,
                generation: generation,
                onOpenFile: self.onOpenFile,
                selectedStepID: self.$viewModel.selectedLearningStepID
            )

        case .architectureMap(let response):
            AIArchitectureMapView(
                response: response,
                generation: generation,
                onOpenFile: self.onOpenFile,
                selectedNodeID: self.$viewModel.selectedArchitectureNodeID
            )

        case .riskMap(let response):
            AIRiskMapView(
                response: response,
                generation: generation,
                onOpenFile: self.onOpenFile,
                selectedRiskID: self.$viewModel.selectedRiskID
            )

        }

    }

}

private struct AIReviewEmptyView: View {

    let visualization: AIVisualization
    let isGenerating: Bool
    let generate: () -> Void

    var body: some View {

        VStack(spacing: 16) {

            DiffyEmptyState(
                symbol: self.visualization.symbol,
                title: self.visualization.title,
                message: self.visualization.purpose
            )
            .frame(maxHeight: 180)
            Button("Generate \(self.visualization.title)", action: self.generate)
                .buttonStyle(.borderedProminent)
                .disabled(self.isGenerating)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

}

extension AIVisualization {

    var symbol: String {

        switch self {

        case .learningPath: "point.topleft.down.curvedto.point.bottomright.up"
        case .architectureMap: "square.3.layers.3d"
        case .riskMap: "scope"

        }

    }

    var purpose: String {

        switch self {

        case .learningPath: "Understand this pull request in a useful order."
        case .architectureMap: "See how changed components fit together."
        case .riskMap: "Find the changes that deserve the closest review."

        }

    }

}
