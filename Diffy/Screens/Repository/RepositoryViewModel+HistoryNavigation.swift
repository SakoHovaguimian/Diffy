import Foundation

extension RepositoryViewModel {

    func resizeHistoryNavigator(by translation: CGFloat, maximumWidth: CGFloat) {

        if self.historyNavigatorDragStartWidth == nil {
            self.historyNavigatorDragStartWidth = min(self.historyNavigatorWidth, maximumWidth)
        }

        let startingWidth = self.historyNavigatorDragStartWidth ?? self.historyNavigatorWidth
        self.historyNavigatorWidth = min(maximumWidth, max(240, startingWidth + translation))

    }

    func finishResizingHistoryNavigator() {
        self.historyNavigatorDragStartWidth = nil
    }

}
