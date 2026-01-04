import Foundation

public struct SteamPackage: Identifiable, Codable, Hashable {
    public let id: Int
    public let name: String
    public let price: PriceInfo?
    public let type: String?

    public init(id: Int, name: String, price: PriceInfo? = nil, type: String? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.type = type
    }
}

public struct SteamDepot: Identifiable, Codable, Hashable {
    public let id: Int
    public let name: String
    public let size: String?
    public let manifest: String?

    public init(id: Int, name: String, size: String? = nil, manifest: String? = nil) {
        self.id = id
        self.name = name
        self.size = size
        self.manifest = manifest
    }
}

public struct SteamBadge: Identifiable, Codable, Hashable {
    public let id: Int
    public let name: String
    public let level: String?
    public let rarity: String?

    public init(id: Int, name: String, level: String? = nil, rarity: String? = nil) {
        self.id = id
        self.name = name
        self.level = level
        self.rarity = rarity
    }
}

public struct SteamChangelogEntry: Identifiable, Codable, Hashable {
    public let id: String
    public let buildID: String?
    public let date: String?
    public let summary: String

    public init(id: String, buildID: String? = nil, date: String? = nil, summary: String) {
        self.id = id
        self.buildID = buildID
        self.date = date
        self.summary = summary
    }
}
