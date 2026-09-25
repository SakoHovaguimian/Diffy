import Foundation

/// Decides when remote GitHub data should be refreshed. The live implementation polls
/// conditionally; a future webhook or push implementation can replace it without
/// changing view models, which only register refresh work under a key.
@MainActor
protocol RemoteChangeMonitoring: AnyObject {

    func beginObserving(
        key: String,
        refresh: @escaping @MainActor () async -> RemoteRefreshOutcome
    )

    func endObserving(key: String)

    func requestImmediateRefresh(key: String)

    func setApplicationActive(_ isActive: Bool)

}
