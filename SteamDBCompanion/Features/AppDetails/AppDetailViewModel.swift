import Foundation
import SwiftUI

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
            async let appData = dataSource.fetchAppDetails(appID: appID)
            async let historyData = dataSource.fetchPriceHistory(appID: appID)
            async let trendData = dataSource.fetchPlayerTrend(appID: appID)
            
            let (fetchedApp, fetchedHistory, fetchedTrend) = try await (appData, historyData, trendData)
            
            self.app = fetchedApp
            self.priceHistory = fetchedHistory
            self.playerTrend = fetchedTrend
        } catch {
            self.errorMessage = "Failed to load details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
