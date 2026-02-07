import Foundation

public protocol SteamDBDataSource {
    /// Searches for apps matching the query.
    func searchApps(query: String) async throws -> [SteamApp]
    
    /// Fetches detailed information for a specific app.
    func fetchAppDetails(appID: Int) async throws -> SteamApp
    
    /// Fetches trending games.
    func fetchTrending() async throws -> [SteamApp]
    
    /// Fetches top selling games.
    func fetchTopSellers() async throws -> [SteamApp]
    
    /// Fetches most played games.
    func fetchMostPlayed() async throws -> [SteamApp]

    /// Fetches apps for a specific collection route.
    func fetchCollection(kind: CollectionKind) async throws -> [SteamApp]
    
    /// Fetches price history for a specific app.
    func fetchPriceHistory(appID: Int) async throws -> PriceHistory
    
    /// Fetches player count trend for a specific app.
    func fetchPlayerTrend(appID: Int) async throws -> PlayerTrend
}
