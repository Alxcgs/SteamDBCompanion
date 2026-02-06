import Foundation
import Combine

@MainActor
public class WishlistViewModel: ObservableObject {
    
    @Published public var wishlistedApps: [SteamApp] = []
    @Published public var isLoading: Bool = false
    @Published public var syncAlertMessage: String = ""
    @Published public var showSyncAlert: Bool = false
    
    private let dataSource: SteamDBDataSource
    private let wishlistManager: WishlistManager
    private let steamSyncService: SteamWishlistSyncService
    
    public init(
        dataSource: SteamDBDataSource,
        wishlistManager: WishlistManager,
        steamSyncService: SteamWishlistSyncService = .shared
    ) {
        self.dataSource = dataSource
        self.wishlistManager = wishlistManager
        self.steamSyncService = steamSyncService
    }
    
    public func loadWishlist() async {
        isLoading = true
        _ = try? await steamSyncService.syncWishlist(into: wishlistManager)
        var apps: [SteamApp] = []
        
        for appID in wishlistManager.wishlist {
            if let app = try? await dataSource.fetchAppDetails(appID: appID) {
                apps.append(app)
            }
        }
        
        self.wishlistedApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        isLoading = false
    }

    public func syncFromSteamAccount() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let count = try await steamSyncService.syncWishlist(into: wishlistManager)
            await loadWishlist()
            syncAlertMessage = count == 0
                ? "Steam wishlist synced. Your Steam wishlist is currently empty."
                : "Steam wishlist synced: \(count) items."
            showSyncAlert = true
        } catch {
            syncAlertMessage = error.localizedDescription
            showSyncAlert = true
        }
    }
}
