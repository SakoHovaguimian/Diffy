import Foundation

enum MockWorkspaceFixtures {

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
            branch: "feature/refine-the-details",
            language: language,
            updatedLabel: "12 minutes ago",
            files: MockFileFixtures.files(projectID: id, language: language),
            commits: self.commits,
            directoryPath: nil
        )

    }

    static let commits: [MockCommit] = [
        MockCommit(id: "a7e2c91", title: "Give every detail a little more room", author: "Sako", date: "Today, 10:42", additions: 42, deletions: 18),
        MockCommit(id: "b4f1d08", title: "Separate theme definitions from presentation", author: "Sako", date: "Yesterday, 16:18", additions: 126, deletions: 54),
        MockCommit(id: "c9a6e32", title: "Refine navigation and keyboard focus", author: "Sako", date: "Sep 22, 09:30", additions: 67, deletions: 23),
        MockCommit(id: "d0b8f64", title: "Introduce the first component collection", author: "Sako", date: "Sep 20, 14:06", additions: 284, deletions: 12)
    ]

}
