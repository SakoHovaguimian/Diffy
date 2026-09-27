import Foundation

extension RepositoryViewModel {

    func restoreHistoryNavigationSelection() {

        self.historyLayout = self.preferencesService.load(RepositoryFileLayout.self, key: "navigation.history.layout") ?? .flat
        self.historySort = self.preferencesService.load(RepositoryFileSort.self, key: "navigation.history.sort") ?? .name

    }

}
