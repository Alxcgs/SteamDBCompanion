import Foundation

public final class RealSteamDBDataSource: SteamDBDataSource {
    
    private let networking: NetworkingService
    private let parser: HTMLParser
    private let baseURL = URL(string: "https://steamdb.info")!
    
    public init(networking: NetworkingService = NetworkingService(), parser: HTMLParser = HTMLParser()) {
        self.networking = networking
        self.parser = parser
    }
    
    public func searchApps(query: String) async throws -> [SteamApp] {
        // SteamDB search URL structure
        let url = baseURL.appendingPathComponent("search/").appending(queryItems: [URLQueryItem(name: "q", value: query)])
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        return try parser.parseSearchResults(html: html)
    }
    
    public func fetchAppDetails(appID: Int) async throws -> SteamApp {
        let cacheKey = "app_details_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: SteamApp.self) {
            return cached
        }
        
        let url = baseURL.appendingPathComponent("app/\(appID)/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let app = try parser.parseAppDetails(html: html, appID: appID)
        await CacheService.shared.save(app, for: cacheKey)
        return app
    }
    
    public func fetchTrending() async throws -> [SteamApp] {
        let cacheKey = "trending"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 1800) { // 30 mins
            return cached
        }
        
        let url = baseURL
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let apps = try parser.parseTrending(html: html)
        await CacheService.shared.save(apps, for: cacheKey)
        return apps
    }
    
    public func fetchTopSellers() async throws -> [SteamApp] {
        let cacheKey = "top_sellers"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 1800) {
            return cached
        }

        let url = baseURL.appendingPathComponent("topsellers/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let apps = try parser.parseTopSellers(html: html)
        let result = apps.isEmpty ? try await fetchTrending() : apps
        await CacheService.shared.save(result, for: cacheKey)
        return result
    }
    
    public func fetchMostPlayed() async throws -> [SteamApp] {
        let cacheKey = "most_played"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamApp].self, expiration: 1800) {
            return cached
        }

        let url = baseURL.appendingPathComponent("graph/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let apps = try parser.parseMostPlayed(html: html)
        let result = apps.isEmpty ? try await fetchTrending() : apps
        await CacheService.shared.save(result, for: cacheKey)
        return result
    }
    
    public func fetchPriceHistory(appID: Int) async throws -> PriceHistory {
        let cacheKey = "price_history_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: PriceHistory.self, expiration: 7200) { // 2hrs
            return cached
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/charts/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let history = try parser.parsePriceHistory(html: html, appID: appID)
        await CacheService.shared.save(history, for: cacheKey)
        return history
    }
    
    public func fetchPlayerTrend(appID: Int) async throws -> PlayerTrend {
        let cacheKey = "player_trend_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: PlayerTrend.self, expiration: 1800) { // 30min
            return cached
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/charts/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let trend = try parser.parsePlayerTrend(html: html, appID: appID)
        await CacheService.shared.save(trend, for: cacheKey)
        return trend
    }

    public func fetchPackages(appID: Int) async throws -> [SteamPackage] {
        let cacheKey = "packages_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamPackage].self, expiration: 3600) {
            return cached
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/packages/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let packages = try parser.parsePackages(html: html)
        await CacheService.shared.save(packages, for: cacheKey)
        return packages
    }

    public func fetchDepots(appID: Int) async throws -> [SteamDepot] {
        let cacheKey = "depots_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamDepot].self, expiration: 3600) {
            return cached
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/depots/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let depots = try parser.parseDepots(html: html)
        await CacheService.shared.save(depots, for: cacheKey)
        return depots
    }

    public func fetchBadges(appID: Int) async throws -> [SteamBadge] {
        let cacheKey = "badges_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamBadge].self, expiration: 3600) {
            return cached
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/badges/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let badges = try parser.parseBadges(html: html)
        await CacheService.shared.save(badges, for: cacheKey)
        return badges
    }

    public func fetchChangelogs(appID: Int) async throws -> [SteamChangelogEntry] {
        let cacheKey = "changelogs_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: [SteamChangelogEntry].self, expiration: 1800) {
            return cached
        }

        let url = baseURL.appendingPathComponent("app/\(appID)/changelogs/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        let changelogs = try parser.parseChangelogs(html: html)
        await CacheService.shared.save(changelogs, for: cacheKey)
        return changelogs
    }
}
