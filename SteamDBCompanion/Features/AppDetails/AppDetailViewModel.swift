import Foundation
import SwiftUI

@MainActor
public class AppDetailViewModel: ObservableObject {
    
    @Published public var app: SteamApp?
    @Published public var priceHistory: PriceHistory?
    @Published public var playerTrend: PlayerTrend?
    @Published public var packages: [SteamPackage] = []
    @Published public var depots: [SteamDepot] = []
    @Published public var badges: [SteamBadge] = []
    @Published public var changelogs: [SteamChangelogEntry] = []
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
            async let packagesData = dataSource.fetchPackages(appID: appID)
            async let depotsData = dataSource.fetchDepots(appID: appID)
            async let badgesData = dataSource.fetchBadges(appID: appID)
            async let changelogData = dataSource.fetchChangelogs(appID: appID)
            
            let (fetchedApp, fetchedHistory, fetchedTrend, fetchedPackages, fetchedDepots, fetchedBadges, fetchedChangelogs) = try await (
                appData,
                historyData,
                trendData,
                packagesData,
                depotsData,
                badgesData,
                changelogData
            )
            
            self.app = fetchedApp
            self.priceHistory = fetchedHistory
            self.playerTrend = fetchedTrend
            self.packages = fetchedPackages
            self.depots = fetchedDepots
            self.badges = fetchedBadges
            self.changelogs = fetchedChangelogs
        } catch {
            self.errorMessage = "Failed to load details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
