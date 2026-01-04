import Foundation

public final class MockSteamDBDataSource: SteamDBDataSource {
    
    public init() {}
    
    public func searchApps(query: String) async throws -> [SteamApp] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        return [
            SteamApp(id: 730, name: "Counter-Strike 2", type: .game, price: nil, platforms: [.windows, .linux]),
            SteamApp(id: 570, name: "Dota 2", type: .game, price: nil, platforms: [.windows, .mac, .linux]),
            SteamApp(id: 271590, name: "Grand Theft Auto V", type: .game, price: PriceInfo(current: 29.99, currency: "USD", discountPercent: 0, initial: 29.99), platforms: [.windows])
        ].filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    public func fetchAppDetails(appID: Int) async throws -> SteamApp {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return SteamApp(
            id: appID,
            name: "Mock Game \(appID)",
            type: .game,
            price: PriceInfo(current: 19.99, currency: "USD", discountPercent: 50, initial: 39.99),
            platforms: [.windows, .mac],
            developer: "Valve",
            publisher: "Valve",
            releaseDate: Date(),
            playerStats: PlayerStats(currentPlayers: 10000, peak24h: 15000, allTimePeak: 100000)
        )
    }
    
    public func fetchTrending() async throws -> [SteamApp] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return [
            SteamApp(id: 1, name: "Trending Game 1", type: .game, price: PriceInfo(current: 59.99, currency: "USD", discountPercent: 0, initial: 59.99)),
            SteamApp(id: 2, name: "Trending Game 2", type: .game, price: PriceInfo(current: 0, currency: "USD", discountPercent: 0, initial: 0)),
            SteamApp(id: 3, name: "Trending Game 3", type: .game, price: PriceInfo(current: 29.99, currency: "USD", discountPercent: 20, initial: 37.49))
        ]
    }
    
    public func fetchTopSellers() async throws -> [SteamApp] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return [
            SteamApp(id: 730, name: "Counter-Strike 2", type: .game),
            SteamApp(id: 570, name: "Dota 2", type: .game),
            SteamApp(id: 1086940, name: "Baldur's Gate 3", type: .game, price: PriceInfo(current: 59.99, currency: "USD", discountPercent: 0, initial: 59.99))
        ]
    }
    
    public func fetchMostPlayed() async throws -> [SteamApp] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return [
            SteamApp(id: 730, name: "Counter-Strike 2", type: .game, playerStats: PlayerStats(currentPlayers: 1200000, peak24h: 1300000, allTimePeak: 1800000)),
            SteamApp(id: 570, name: "Dota 2", type: .game, playerStats: PlayerStats(currentPlayers: 600000, peak24h: 700000, allTimePeak: 1200000))
        ]
    }
    
    public func fetchPriceHistory(appID: Int) async throws -> PriceHistory {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate 30 days of mock price history with some variation
        let points = (0..<30).reversed().map { daysAgo -> PriceHistoryPoint in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let basePrice = 29.99
            let variation = Double.random(in: -5...5)
            let price = max(basePrice + variation, 19.99)
            let discount = price < 25 ? Int.random(in: 20...50) : 0
            
            return PriceHistoryPoint(date: date, price: price, discount: discount)
        }
        
        return PriceHistory(appID: appID, currency: "USD", points: points)
    }
    
    public func fetchPlayerTrend(appID: Int) async throws -> PlayerTrend {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let calendar = Calendar.current
        let now = Date()
        
        // Generate 24 hours of player count data (hourly)
        let basePlayers = Int.random(in: 50000...200000)
        let points = (0..<24).reversed().map { hoursAgo -> PlayerCountPoint in
            let date = calendar.date(byAdding: .hour, value: -hoursAgo, to: now)!
            // Simulate realistic player count fluctuation (peak during evening hours)
            let hour = calendar.component(.hour, from: date)
            let peakMultiplier = hour >= 18 && hour <= 23 ? 1.3 : (hour >= 6 && hour <= 12 ? 0.8 : 1.0)
            let variation = Double.random(in: -0.1...0.1)
            let playerCount = Int(Double(basePlayers) * peakMultiplier * (1 + variation))
            
            return PlayerCountPoint(date: date, playerCount: playerCount)
        }
        
        return PlayerTrend(appID: appID, points: points)
    }

    public func fetchPackages(appID: Int) async throws -> [SteamPackage] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return [
            SteamPackage(id: 12345, name: "Standard Edition", price: PriceInfo(current: 29.99, currency: "USD", discountPercent: 0, initial: 29.99), type: "Game"),
            SteamPackage(id: 23456, name: "Deluxe Bundle", price: PriceInfo(current: 49.99, currency: "USD", discountPercent: 10, initial: 59.99), type: "Bundle")
        ]
    }

    public func fetchDepots(appID: Int) async throws -> [SteamDepot] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return [
            SteamDepot(id: 123456, name: "Windows Content", size: "12.3 GB", manifest: "7890123456789012345"),
            SteamDepot(id: 234567, name: "Mac Content", size: "11.8 GB", manifest: "8901234567890123456")
        ]
    }

    public func fetchBadges(appID: Int) async throws -> [SteamBadge] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return [
            SteamBadge(id: 1, name: "Collector Badge", level: "Level 1", rarity: "Common"),
            SteamBadge(id: 2, name: "Foil Badge", level: "Level 1", rarity: "Rare")
        ]
    }

    public func fetchChangelogs(appID: Int) async throws -> [SteamChangelogEntry] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return [
            SteamChangelogEntry(id: "build-1001", buildID: "1001", date: "2024-04-01", summary: "Added new maps and balance tweaks."),
            SteamChangelogEntry(id: "build-1002", buildID: "1002", date: "2024-05-15", summary: "Improved matchmaking performance.")
        ]
    }
}
