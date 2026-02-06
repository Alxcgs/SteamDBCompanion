import Foundation
import SwiftUI
import Combine

@MainActor
public class AppDetailViewModel: ObservableObject {
    
    @Published public var app: SteamApp?
    @Published public var priceHistory: PriceHistory?
    @Published public var playerTrend: PlayerTrend?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let dataSource: SteamDBDataSource
    private let appID: Int
    
    public init(appID: Int, dataSource: SteamDBDataSource = MockSteamDBDataSource()) {
        self.appID = appID
        self.dataSource = dataSource
    }
    
    public func loadDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedApp = try await dataSource.fetchAppDetails(appID: appID)
            self.app = fetchedApp

            async let historyData: PriceHistory? = try? dataSource.fetchPriceHistory(appID: appID)
            async let trendData: PlayerTrend? = try? dataSource.fetchPlayerTrend(appID: appID)
            self.priceHistory = await historyData
            self.playerTrend = await trendData
        } catch {
            self.errorMessage = "Failed to load details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
