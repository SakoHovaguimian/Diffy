import Foundation
import Combine

@MainActor
final class WorkspaceIconPickerViewModel: ViewModel {

    let loggerName = "WORKSPACE_ICON_PICKER_VIEW_MODEL"
    private let importController: WorkspaceIconImportController
    @Published private(set) var errorMessage: String?
    @Published private(set) var isImporting = false

    init(importController: WorkspaceIconImportController? = nil) {
        self.importController = importController ?? WorkspaceIconImportController()
    }

    func clearError() {
        self.errorMessage = nil
    }

    func chooseIcon() async -> WorkspaceCustomIcon? {

        guard !self.isImporting else { return nil }
        self.isImporting = true
        self.errorMessage = nil
        defer { self.isImporting = false }

        do {
            return try await self.importController.chooseIcon()
        } catch is CancellationError {
            return nil
        } catch {

            self.errorMessage = "Couldn’t open this image. Choose another icon."
            return nil

        }

    }

}
