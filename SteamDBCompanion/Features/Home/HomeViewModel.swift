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
    
    public init(dataSource: SteamDBDataSource = MockSteamDBDataSource()) {
        self.dataSource = dataSource
    }
    
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let trendingResult = try await dataSource.fetchTrending()
            self.trendingApps = trendingResult

            let topResult = try await dataSource.fetchTopSellers()
            self.topSellers = topResult
        } catch {
            self.errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
