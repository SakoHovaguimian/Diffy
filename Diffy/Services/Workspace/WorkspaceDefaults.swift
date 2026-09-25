import Foundation

/// Organization defaults shared by every runtime. Starter Bucket identifiers match the
/// Milestone 0 Buckets so migrated folder records keep their Bucket membership.
enum WorkspaceDefaults {

    static let starterBuckets: [Bucket] = [
        Bucket(id: "ios", title: "iOS", subtitle: "Made for the everyday", symbol: "square.stack.3d.up", accentHex: "7862D9"),
        Bucket(id: "backend", title: "Backend", subtitle: "Behind the scenes", symbol: "server.rack", accentHex: "319B90"),
        Bucket(id: "personal", title: "Personal", subtitle: "A little room to explore", symbol: "sparkles", accentHex: "D39553")
    ]

}
