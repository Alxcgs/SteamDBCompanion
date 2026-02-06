import Foundation

public enum ChartRange: String, Codable, Hashable {
    case day
    case week
    case month
    case year
    case all
}

public enum CollectionKind: String, Codable, Hashable, CaseIterable {
    case topRated = "top-rated"
    case topSellersGlobal = "topsellers-global"
    case topSellersWeekly = "topsellers-weekly"
    case mostFollowed = "mostfollowed"
    case mostWished = "mostwished"
    case wishlists = "wishlists"
    case dailyActiveUsers = "dailyactiveusers"
    case sales
    case charts
    case calendar
    case pricechanges
    case upcoming
    case freepackages
    case bundles
}

public struct GatewayApp: Identifiable, Codable, Hashable {
    public let id: Int
    public let name: String
    public let type: String
    public let currentPrice: Double?
    public let currency: String?
    public let discountPercent: Int?
    public let initialPrice: Double?
    public let platforms: [Platform]
    public let developer: String?
    public let publisher: String?
    public let currentPlayers: Int?
    public let peak24h: Int?
    public let allTimePeak: Int?

    public init(
        id: Int,
        name: String,
        type: String,
        currentPrice: Double? = nil,
        currency: String? = nil,
        discountPercent: Int? = nil,
        initialPrice: Double? = nil,
        platforms: [Platform] = [],
        developer: String? = nil,
        publisher: String? = nil,
        currentPlayers: Int? = nil,
        peak24h: Int? = nil,
        allTimePeak: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currentPrice = currentPrice
        self.currency = currency
        self.discountPercent = discountPercent
        self.initialPrice = initialPrice
        self.platforms = platforms
        self.developer = developer
        self.publisher = publisher
        self.currentPlayers = currentPlayers
        self.peak24h = peak24h
        self.allTimePeak = allTimePeak
    }
}

public struct HomePayload: Codable, Hashable {
    public let trending: [GatewayApp]
    public let topSellers: [GatewayApp]
    public let mostPlayed: [GatewayApp]
    public let stale: Bool

    public init(trending: [GatewayApp], topSellers: [GatewayApp], mostPlayed: [GatewayApp], stale: Bool = false) {
        self.trending = trending
        self.topSellers = topSellers
        self.mostPlayed = mostPlayed
        self.stale = stale
    }
}

public struct SearchPayload: Codable, Hashable {
    public let results: [GatewayApp]
    public let page: Int
    public let total: Int?
    public let stale: Bool

    public init(results: [GatewayApp], page: Int = 1, total: Int? = nil, stale: Bool = false) {
        self.results = results
        self.page = page
        self.total = total
        self.stale = stale
    }
}

public struct AppOverviewPayload: Codable, Hashable {
    public let app: GatewayApp
    public let stale: Bool

    public init(app: GatewayApp, stale: Bool = false) {
        self.app = app
        self.stale = stale
    }
}

public struct GatewayPricePoint: Codable, Hashable {
    public let date: Date
    public let price: Double
    public let discount: Int

    public init(date: Date, price: Double, discount: Int = 0) {
        self.date = date
        self.price = price
        self.discount = discount
    }
}

public struct GatewayPlayerPoint: Codable, Hashable {
    public let date: Date
    public let players: Int

    public init(date: Date, players: Int) {
        self.date = date
        self.players = players
    }
}

public struct AppChartsPayload: Codable, Hashable {
    public let appID: Int
    public let currency: String
    public let priceHistory: [GatewayPricePoint]
    public let playerTrend: [GatewayPlayerPoint]
    public let stale: Bool

    public init(appID: Int, currency: String, priceHistory: [GatewayPricePoint], playerTrend: [GatewayPlayerPoint], stale: Bool = false) {
        self.appID = appID
        self.currency = currency
        self.priceHistory = priceHistory
        self.playerTrend = playerTrend
        self.stale = stale
    }
}

public struct CollectionPayload: Codable, Hashable {
    public let kind: CollectionKind
    public let items: [GatewayApp]
    public let stale: Bool

    public init(kind: CollectionKind, items: [GatewayApp], stale: Bool = false) {
        self.kind = kind
        self.items = items
        self.stale = stale
    }
}

public struct WatchlistPayload: Codable, Hashable {
    public let installationID: String
    public let appIDs: [Int]
    public let updatedAt: Date

    public init(installationID: String, appIDs: [Int], updatedAt: Date = Date()) {
        self.installationID = installationID
        self.appIDs = appIDs
        self.updatedAt = updatedAt
    }
}

public struct AlertDiff: Identifiable, Codable, Hashable {
    public enum AlertType: String, Codable, Hashable {
        case priceDrop
        case priceRise
        case playerSpike
        case playerDrop
        case unknown
    }

    public let id: UUID
    public let appID: Int
    public let type: AlertType
    public let oldValue: Double
    public let newValue: Double
    public let detectedAt: Date

    public init(
        id: UUID = UUID(),
        appID: Int,
        type: AlertType,
        oldValue: Double,
        newValue: Double,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.appID = appID
        self.type = type
        self.oldValue = oldValue
        self.newValue = newValue
        self.detectedAt = detectedAt
    }
}

public protocol SteamDBGatewayClient {
    func fetchNavigationRoutes() async throws -> [RouteDescriptor]
    func fetchHome() async throws -> HomePayload
    func search(query: String, page: Int) async throws -> SearchPayload
    func fetchAppOverview(appID: Int) async throws -> AppOverviewPayload
    func fetchAppCharts(appID: Int, range: ChartRange) async throws -> AppChartsPayload
    func fetchCollection(kind: CollectionKind) async throws -> CollectionPayload
    func fetchWatchlist(installationID: String) async throws -> WatchlistPayload
    func updateWatchlist(_ payload: WatchlistPayload) async throws -> WatchlistPayload
}

public extension GatewayApp {
    var asSteamApp: SteamApp {
        let price: PriceInfo?
        if let currentPrice, let currency {
            price = PriceInfo(
                current: currentPrice,
                currency: currency,
                discountPercent: discountPercent ?? 0,
                initial: initialPrice ?? currentPrice
            )
        } else {
            price = nil
        }

        let appType = AppType(rawValue: type.lowercased()) ?? .unknown
        let stats: PlayerStats?
        if let currentPlayers, let peak24h, let allTimePeak {
            stats = PlayerStats(currentPlayers: currentPlayers, peak24h: peak24h, allTimePeak: allTimePeak)
        } else {
            stats = nil
        }

        return SteamApp(
            id: id,
            name: name,
            type: appType,
            price: price,
            platforms: platforms,
            developer: developer,
            publisher: publisher,
            playerStats: stats
        )
    }
}

public extension AppChartsPayload {
    var asPriceHistory: PriceHistory {
        let points = priceHistory.map { item in
            PriceHistoryPoint(date: item.date, price: item.price, discount: item.discount)
        }
        return PriceHistory(appID: appID, currency: currency, points: points)
    }

    var asPlayerTrend: PlayerTrend {
        let points = playerTrend.map { item in
            PlayerCountPoint(date: item.date, playerCount: item.players)
        }
        return PlayerTrend(appID: appID, points: points)
    }
}
