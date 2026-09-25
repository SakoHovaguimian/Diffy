import Foundation

extension GitHubAppConfiguration {

    static func bundled() -> GitHubAppConfiguration {

        func value(_ key: String) -> String? {

            let value = (Bundle.main.object(forInfoDictionaryKey: key) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return value?.isEmpty == false && value?.contains("$(") == false ? value : nil

        }

        return GitHubAppConfiguration(clientID: value("DiffyGitHubClientID"), host: value("DiffyGitHubHost") ?? "github.com", appSlug: value("DiffyGitHubAppSlug"))

    }

}
