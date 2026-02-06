import Foundation

public final class RealSteamDBDataSource: SteamDBDataSource {
    private let gateway: SteamDBGatewayClient
    private let repository: SteamDBRepository
    private let networking: NetworkingService
    private let parser: HTMLParser
    private let baseURL = URL(string: "https://steamdb.info")!
    
    public init(
        gateway: SteamDBGatewayClient = HTTPSteamDBGatewayClient(),
        repository: SteamDBRepository = SteamDBRepository(),
        networking: NetworkingService = NetworkingService(),
        parser: HTMLParser = HTMLParser()
    ) {
        self.gateway = gateway
        self.repository = repository
        self.networking = networking
        self.parser = parser
    }

    public func fetchNavigationRoutes() async -> [RouteDescriptor] {
        do {
            return try await gateway.fetchNavigationRoutes()
        } catch {
            return RouteRegistry.defaultDescriptors
        }
    }

    public func searchApps(query: String) async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "search_\(query)_1", expiration: 600) {
                try await self.gateway.search(query: query, page: 1)
            }
            return result.value.results.map(\.asSteamApp)
        } catch {
            return try await fallbackSearch(query: query)
        }
    }
    
    public func fetchAppDetails(appID: Int) async throws -> SteamApp {
        do {
            let result = try await repository.fetch(cacheKey: "app_details_\(appID)", expiration: 1800) {
                try await self.gateway.fetchAppOverview(appID: appID)
            }
            return result.value.app.asSteamApp
        } catch {
            return try await fallbackAppDetails(appID: appID)
        }
    }
    
    public func fetchTrending() async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "home_payload", expiration: 900) {
                try await self.gateway.fetchHome()
            }
            return result.value.trending.map(\.asSteamApp)
        } catch {
            return try await fallbackTrending()
        }
    }
    
    public func fetchTopSellers() async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "home_payload", expiration: 900) {
                try await self.gateway.fetchHome()
            }
            return result.value.topSellers.map(\.asSteamApp)
        } catch {
            return try await fallbackTrending()
        }
    }
    
    public func fetchMostPlayed() async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "home_payload", expiration: 900) {
                try await self.gateway.fetchHome()
            }
            if !result.value.mostPlayed.isEmpty {
                return result.value.mostPlayed.map(\.asSteamApp)
            }
        } catch {
            // Ignore and try collection endpoint.
        }

        do {
            let result = try await repository.fetch(cacheKey: "collection_daily_active_users", expiration: 900) {
                try await self.gateway.fetchCollection(kind: .dailyActiveUsers)
            }
            return result.value.items.map(\.asSteamApp)
        } catch {
            return try await fallbackTrending()
        }
    }
    
    public func fetchPriceHistory(appID: Int) async throws -> PriceHistory {
        do {
            let result = try await repository.fetch(cacheKey: "app_charts_\(appID)_month", expiration: 900) {
                try await self.gateway.fetchAppCharts(appID: appID, range: .month)
            }
            return result.value.asPriceHistory
        } catch {
            if let cached = await CacheService.shared.load(key: "price_history_\(appID)", type: PriceHistory.self, expiration: 86_400) {
                return cached
            }
            return PriceHistory(appID: appID, currency: "USD", points: [])
        }
    }
    
    public func fetchPlayerTrend(appID: Int) async throws -> PlayerTrend {
        do {
            let result = try await repository.fetch(cacheKey: "app_charts_\(appID)_day", expiration: 900) {
                try await self.gateway.fetchAppCharts(appID: appID, range: .day)
            }
            return result.value.asPlayerTrend
        } catch {
            if let cached = await CacheService.shared.load(key: "player_trend_\(appID)", type: PlayerTrend.self, expiration: 86_400) {
                return cached
            }
            return PlayerTrend(appID: appID, points: [])
        }
    }

    private func fallbackSearch(query: String) async throws -> [SteamApp] {
        let url = baseURL.appendingPathComponent("search/").appending(queryItems: [URLQueryItem(name: "q", value: query)])
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return try parser.parseTrending(html: html)
    }

    private func fallbackAppDetails(appID: Int) async throws -> SteamApp {
        let cacheKey = "legacy_app_details_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: SteamApp.self, expiration: 86_400) {
            return cached
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let app = try parser.parseAppDetails(html: html, appID: appID)
        await CacheService.shared.save(app, for: cacheKey)
        return app
    }

    private func fallbackTrending() async throws -> [SteamApp] {
        let cacheKey = "legacy_trending"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return cached
        }

        let data = try await networking.fetchData(url: baseURL)
        let html = String(data: data, encoding: .utf8) ?? ""
        let apps = try parser.parseTrending(html: html)
        await CacheService.shared.save(apps, for: cacheKey)
        return apps
    }
}
