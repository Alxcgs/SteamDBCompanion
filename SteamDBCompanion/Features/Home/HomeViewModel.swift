import Foundation
import SwiftUI
import Combine

@MainActor
public class HomeViewModel: ObservableObject {
    
    @Published public var trendingApps: [SteamApp] = []
    @Published public var topSellers: [SteamApp] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let dataSource: SteamDBDataSource
    private var lastLoadedAt: Date?
    
    public init(dataSource: SteamDBDataSource? = nil) {
        self.dataSource = dataSource ?? MockSteamDBDataSource()
    }
    
    public func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let trendingResult = try await dataSource.fetchTrending()
            self.trendingApps = trendingResult

            let topResult = try await dataSource.fetchTopSellers()
            self.topSellers = topResult
            self.lastLoadedAt = Date()
        } catch {
            self.errorMessage = "\(L10n.tr("home.error_load", fallback: "Failed to load data")): \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    public func refreshIfStale(maxAge: TimeInterval = 300) async {
        guard !isLoading else { return }

        if let lastLoadedAt,
           Date().timeIntervalSince(lastLoadedAt) < maxAge,
           !trendingApps.isEmpty,
           !topSellers.isEmpty {
            return
        }

        await loadData()
    }
}
