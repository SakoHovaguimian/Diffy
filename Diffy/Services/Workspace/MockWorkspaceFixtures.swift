import Foundation

enum MockWorkspaceFixtures {

    private static let addedAt = Date(timeIntervalSince1970: 1_700_000_000)

    static let buckets: [Bucket] = [
        Bucket(id: "ios", title: "iOS", subtitle: "Made for the everyday", symbol: "square.stack.3d.up", accentHex: "7862D9"),
        Bucket(id: "backend", title: "Backend", subtitle: "Behind the scenes", symbol: "server.rack", accentHex: "319B90"),
        Bucket(id: "personal", title: "Personal", subtitle: "A little room to explore", symbol: "sparkles", accentHex: "D39553")
    ]

    static let projects: [RepositoryProject] = [
        project("rune", name: "Rune", subtitle: "A considered design system", bucket: "ios", symbol: "square.stack.3d.up.fill", language: "Swift"),
        project("grimoire", name: "Grimoire", subtitle: "The beginning of something good", bucket: "ios", symbol: "book.closed.fill", language: "Swift"),
        project("hatch", name: "Hatch", subtitle: "Small ideas, taking shape", bucket: "ios", symbol: "leaf.fill", language: "Swift"),
        project("joblens", name: "JobLens iOS", subtitle: "A clearer next chapter", bucket: "ios", symbol: "viewfinder", language: "Swift"),
        project("obelisk", name: "Obelisk", subtitle: "A foundation for your next API", bucket: "backend", symbol: "server.rack", language: "TypeScript"),
        project("joblens-api", name: "JobLens API", subtitle: "Connected by design", bucket: "backend", symbol: "network", language: "TypeScript"),
        project("stormkeep", name: "Stormkeep", subtitle: "Ideas worth keeping", bucket: "personal", symbol: "mountain.2.fill", language: "Swift")
    ]

    private static func project(
        _ id: String,
        name: String,
        subtitle: String,
        bucket: String,
        symbol: String,
        language: String
    ) -> RepositoryProject {

        RepositoryProject(
            id: id,
            name: name,
            subtitle: subtitle,
            bucketID: bucket,
            symbol: symbol,
            checkout: nil,
            gitHubLink: nil,
            gitHubAccountID: nil,
            addedAt: self.addedAt
        )

    }

    static let commits: [RepositoryCommit] = [
        commit("a7e2c91", title: "Give every detail a little more room", hoursAgo: 2, additions: 42, deletions: 18),
        commit("b4f1d08", title: "Separate theme definitions from presentation", hoursAgo: 20, additions: 126, deletions: 54),
        commit("c9a6e32", title: "Refine navigation and keyboard focus", hoursAgo: 52, additions: 67, deletions: 23),
        commit("d0b8f64", title: "Introduce the first component collection", hoursAgo: 95, additions: 284, deletions: 12)
    ]

    static func files(for projectID: String) -> [DiffFile] {
        fileCollections[projectID] ?? []
    }

    static func branch(for projectID: String) -> String {
        languages[projectID] == nil ? "" : "feature/refine-the-details"
    }

    private static let languages = [
        "rune": "Swift",
        "grimoire": "Swift",
        "hatch": "Swift",
        "joblens": "Swift",
        "obelisk": "TypeScript",
        "joblens-api": "TypeScript",
        "stormkeep": "Swift"
    ]

    private static let fileCollections = Dictionary(uniqueKeysWithValues: languages.map { projectID, language in
        (projectID, MockFileFixtures.files(projectID: projectID, language: language))
    })

    private static func commit(
        _ id: String,
        title: String,
        hoursAgo: Int,
        additions: Int,
        deletions: Int
    ) -> RepositoryCommit {

        RepositoryCommit(
            id: id,
            title: title,
            authorName: "Sako",
            authoredAt: self.addedAt.addingTimeInterval(-Double(hoursAgo * 3_600)),
            parentIDs: [],
            additions: additions,
            deletions: deletions
        )

    }

}

// MARK: - Prototype Presentation

extension RepositoryProject {

    var branch: String {
        MockWorkspaceFixtures.branch(for: self.id)
    }

    var files: [DiffFile] {
        MockWorkspaceFixtures.files(for: self.id)
    }

    var commits: [RepositoryCommit] {
        self.files.isEmpty ? [] : MockWorkspaceFixtures.commits
    }

    var directoryPath: String? {
        self.checkout?.lastKnownPath
    }

    var changeCount: Int {
        self.files.filter { $0.status != .identical }.count
    }

}
