import Foundation

public final class RealSteamDBDataSource: SteamDBDataSource {
    private let gateway: SteamDBGatewayClient
    private let repository: SteamDBRepository
    private let networking: NetworkingService
    private let parser: HTMLParser
    private let baseURL = URL(string: "https://steamdb.info")!
    private let storeFeaturedURL = URL(string: "https://store.steampowered.com/api/featuredcategories?cc=us&l=en")!
    
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
            return uniqueApps(result.value.trending.map(\.asSteamApp))
        } catch {
            return uniqueApps(await fallbackTrending())
        }
    }
    
    public func fetchTopSellers() async throws -> [SteamApp] {
        do {
            let result = try await repository.fetch(cacheKey: "home_payload", expiration: 900) {
                try await self.gateway.fetchHome()
            }
            return uniqueApps(result.value.topSellers.map(\.asSteamApp))
        } catch {
            return uniqueApps(await fallbackTopSellers())
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
            return uniqueApps(result.value.items.map(\.asSteamApp))
        } catch {
            let fallback = await fallbackTopSellers()
            if !fallback.isEmpty {
                return uniqueApps(fallback)
            }
            return uniqueApps(await fallbackTrending())
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

    private func fallbackTrending() async -> [SteamApp] {
        let cacheKey = "legacy_trending"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return cached
        }

        do {
            let data = try await networking.fetchData(url: baseURL)
            let html = String(data: data, encoding: .utf8) ?? ""
            let apps = try parser.parseTrending(html: html)
            if !apps.isEmpty {
                await CacheService.shared.save(apps, for: cacheKey)
                return apps
            }
        } catch {
            // Continue to stale/store fallbacks.
        }

        if let stale = await CacheService.shared.loadAllowExpired(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return stale.value
        }

        let storeFallback = await fetchStoreTrending()
        if !storeFallback.isEmpty {
            await CacheService.shared.save(storeFallback, for: cacheKey)
        }
        return storeFallback
    }

    private func fallbackTopSellers() async -> [SteamApp] {
        let cacheKey = "legacy_top_sellers"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return cached
        }

        let storeFallback = await fetchStoreTopSellers()
        if !storeFallback.isEmpty {
            await CacheService.shared.save(storeFallback, for: cacheKey)
            return storeFallback
        }

        if let stale = await CacheService.shared.loadAllowExpired(key: cacheKey, type: [SteamApp].self, expiration: 3600) {
            return stale.value
        }

        return await fallbackTrending()
    }

    private func fetchStoreTrending() async -> [SteamApp] {
        do {
            let payload = try await repository.fetch(cacheKey: "steam_store_featured", expiration: 900) {
                try await self.networking.fetch(url: self.storeFeaturedURL, type: StoreFeaturedPayload.self)
            }

            let specials = (payload.value.specials?.items ?? []).map(asSteamApp)
            if !specials.isEmpty {
                return specials
            }

            return (payload.value.featuredWin?.items ?? []).map(asSteamApp)
        } catch {
            return []
        }
    }

    private func fetchStoreTopSellers() async -> [SteamApp] {
        do {
            let payload = try await repository.fetch(cacheKey: "steam_store_featured", expiration: 900) {
                try await self.networking.fetch(url: self.storeFeaturedURL, type: StoreFeaturedPayload.self)
            }
            return (payload.value.topSellers?.items ?? []).map(asSteamApp)
        } catch {
            return []
        }
    }

    private func asSteamApp(_ item: StoreFeaturedItem) -> SteamApp {
        var platforms: [Platform] = []
        if item.windowsAvailable == true { platforms.append(.windows) }
        if item.macAvailable == true { platforms.append(.mac) }
        if item.linuxAvailable == true { platforms.append(.linux) }
        if platforms.isEmpty { platforms = [.windows] }

        let price: PriceInfo?
        if let finalPrice = item.finalPrice, finalPrice > 0 {
            let initialPrice = item.originalPrice ?? finalPrice
            price = PriceInfo(
                current: Double(finalPrice) / 100.0,
                currency: "USD",
                discountPercent: item.discountPercent ?? 0,
                initial: Double(initialPrice) / 100.0
            )
        } else {
            price = nil
        }

        return SteamApp(
            id: item.id,
            name: item.name,
            type: .game,
            price: price,
            platforms: platforms
        )
    }

    private func uniqueApps(_ apps: [SteamApp]) -> [SteamApp] {
        var seenIDs = Set<Int>()
        return apps.filter { app in
            seenIDs.insert(app.id).inserted
        }
    }
}

private struct StoreFeaturedPayload: Codable {
    let specials: StoreFeaturedSection?
    let topSellers: StoreFeaturedSection?
    let featuredWin: StoreFeaturedSection?
}

private struct StoreFeaturedSection: Codable {
    let items: [StoreFeaturedItem]
}

private struct StoreFeaturedItem: Codable {
    let id: Int
    let name: String
    let discountPercent: Int?
    let originalPrice: Int?
    let finalPrice: Int?
    let windowsAvailable: Bool?
    let macAvailable: Bool?
    let linuxAvailable: Bool?
}
