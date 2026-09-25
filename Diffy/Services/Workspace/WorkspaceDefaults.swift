import Foundation

/// Organization defaults shared by every runtime.
enum WorkspaceDefaults {

    static let starterBuckets: [Bucket] = [
        Bucket(id: "personal", title: "Personal", subtitle: "A little room to explore", symbol: "sparkles", accentHex: "319B90")
    ]

    static let retiredBucketIDs: Set<String> = ["ios", "backend"]

    private static let legacyBuckets: [Bucket] = [
        Bucket(id: "ios", title: "iOS", subtitle: "Made for the everyday", symbol: "square.stack.3d.up", accentHex: "7862D9"),
        Bucket(id: "backend", title: "Backend", subtitle: "Behind the scenes", symbol: "server.rack", accentHex: "319B90"),
        Bucket(id: "personal", title: "Personal", subtitle: "A little room to explore", symbol: "sparkles", accentHex: "D39553")
    ]

    static func migrateStarterBuckets(_ buckets: [Bucket]) -> [Bucket] {

        buckets.compactMap { bucket in

            guard let legacy = self.legacyBuckets.first(where: { $0.id == bucket.id }),
                  bucket.title == legacy.title,
                  bucket.subtitle == legacy.subtitle,
                  bucket.symbol == legacy.symbol,
                  bucket.accentHex == legacy.accentHex,
                  bucket.defaultBranch == legacy.defaultBranch else {
                return bucket
            }

            guard bucket.id == "personal" else { return nil }

            var updated = bucket
            updated.accentHex = self.starterBuckets[0].accentHex
            return updated

        }

    }

}
