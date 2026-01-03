import Foundation
import SwiftUI

@MainActor
public class HomeViewModel: ObservableObject {
    
    @Published public var trendingApps: [SteamApp] = []
    @Published public var topSellers: [SteamApp] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let dataSource: SteamDBDataSource
    
    public init(dataSource: SteamDBDataSource = MockSteamDBDataSource()) {
        self.dataSource = dataSource
    }
    
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let trending = dataSource.fetchTrending()
            async let top = dataSource.fetchTopSellers()
            
            let (trendingResult, topResult) = try await (trending, top)
            
            self.trendingApps = trendingResult
            self.topSellers = topResult
        } catch {
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
