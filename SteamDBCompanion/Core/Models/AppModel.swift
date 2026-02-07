import Foundation

public struct SteamApp: Identifiable, Codable, Hashable {
    public let id: Int
    public let name: String
    public let type: AppType
    public let price: PriceInfo?
    public let headerImageURL: URL?
    public let shortDescription: String?
    public let platforms: [Platform]
    public let developer: String?
    public let publisher: String?
    public let releaseDate: Date?
    public let playerStats: PlayerStats?
    
    public init(
        id: Int,
        name: String,
        type: AppType,
        price: PriceInfo? = nil,
        headerImageURL: URL? = nil,
        shortDescription: String? = nil,
        platforms: [Platform] = [],
        developer: String? = nil,
        publisher: String? = nil,
        releaseDate: Date? = nil,
        playerStats: PlayerStats? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.price = price
        self.headerImageURL = headerImageURL
        self.shortDescription = shortDescription
        self.platforms = platforms
        self.developer = developer
        self.publisher = publisher
        self.releaseDate = releaseDate
        self.playerStats = playerStats
    }
}

public enum AppType: String, Codable, Hashable {
    case game
    case dlc
    case application
    case tool
    case music
    case unknown
}

public enum Platform: String, Codable, Hashable {
    case windows
    case mac
    case linux
    
    public var icon: String {
        switch self {
        case .windows: return "desktopcomputer"
        case .mac: return "applelogo"
        case .linux: return "server.rack"
        }
    }
}

public struct PriceInfo: Codable, Hashable {
    public let current: Double
    public let currency: String
    public let discountPercent: Int
    public let initial: Double
    
    public var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = preferredLocale()
        return formatter.string(from: NSNumber(value: current)) ?? "\(currency)\(current)"
    }
    
    public init(current: Double, currency: String, discountPercent: Int, initial: Double) {
        self.current = current
        self.currency = currency
        self.discountPercent = discountPercent
        self.initial = initial
    }

    private func preferredLocale() -> Locale {
        let countryRaw = UserDefaults.standard.string(forKey: "steamStoreCountryCode")?.lowercased() ?? "auto"
        let languageRaw = UserDefaults.standard.string(forKey: "appLanguageMode")?.lowercased()
            ?? UserDefaults.standard.string(forKey: "steamStoreLanguageCode")?.lowercased()
            ?? Locale.current.language.languageCode?.identifier.lowercased()
            ?? "en"

        if countryRaw == "auto" || countryRaw.count != 2 {
            if languageRaw.count == 2 {
                return Locale(identifier: languageRaw)
            }
            return .autoupdatingCurrent
        }

        let identifier = "\(languageRaw)_\(countryRaw.uppercased())"
        return Locale(identifier: identifier)
    }
}

public struct PlayerStats: Codable, Hashable {
    public let currentPlayers: Int
    public let peak24h: Int
    public let allTimePeak: Int
    
    public init(currentPlayers: Int, peak24h: Int, allTimePeak: Int) {
        self.currentPlayers = currentPlayers
        self.peak24h = peak24h
        self.allTimePeak = allTimePeak
    }
}
