import Foundation

extension RepositoryProject {

    enum CodingKeys: String, CodingKey {
        case id, name, displayName, subtitle, bucketID, symbol, checkout, gitHubLink, gitHubAccountID, addedAt
    }

    init(from decoder: Decoder) throws {

        let values = try decoder.container(keyedBy: CodingKeys.self)
        let name = try values.decode(String.self, forKey: .name)

        self.init(
            id: try values.decode(String.self, forKey: .id),
            name: name,
            displayName: try values.decodeIfPresent(String.self, forKey: .displayName) ?? name,
            subtitle: try values.decode(String.self, forKey: .subtitle),
            bucketID: try values.decode(String.self, forKey: .bucketID),
            symbol: try values.decode(String.self, forKey: .symbol),
            checkout: try values.decodeIfPresent(LocalCheckoutReference.self, forKey: .checkout),
            gitHubLink: try values.decodeIfPresent(GitHubRepositoryLink.self, forKey: .gitHubLink),
            gitHubAccountID: try values.decodeIfPresent(String.self, forKey: .gitHubAccountID),
            addedAt: try values.decode(Date.self, forKey: .addedAt)
        )

    }

}
