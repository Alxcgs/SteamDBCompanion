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
        
        // Reuse trending parser or create specific search parser
        return try parser.parseTrending(html: html) 
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
        // Similar to trending, might need different selector
        return try await fetchTrending() 
    }
    
    public func fetchMostPlayed() async throws -> [SteamApp] {
        let url = baseURL.appendingPathComponent("graph/")
        let data = try await networking.fetchData(url: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        return try parser.parseTrending(html: html)
    }
    
    public func fetchPriceHistory(appID: Int) async throws -> PriceHistory {
        // TODO: Parse price history from SteamDB charts page
        // For now, return empty history
        // In production, would parse from: https://steamdb.info/app/{appID}/charts/
        
        let cacheKey = "price_history_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: PriceHistory.self, expiration: 7200) { // 2hrs
            return cached
        }
        
        // Stub implementation - would parse HTML chart data in production
        let history = PriceHistory(appID: appID, currency: "USD", points: [])
        await CacheService.shared.save(history, for: cacheKey)
        return history
    }
    
    public func fetchPlayerTrend(appID: Int) async throws -> PlayerTrend {
        // TODO: Parse player trend from SteamDB charts page
        // For now, return empty trend
        // In production, would parse from: https://steamdb.info/app/{appID}/charts/
        
        let cacheKey = "player_trend_\(appID)"
        if let cached = await CacheService.shared.load(key: cacheKey, type: PlayerTrend.self, expiration: 1800) { // 30min
            return cached
        }
        
        // Stub implementation
        let trend = PlayerTrend(appID: appID, points: [])
        await CacheService.shared.save(trend, for: cacheKey)
        return trend
    }
}
