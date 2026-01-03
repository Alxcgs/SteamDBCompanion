import Foundation
import Combine

@MainActor
public class WishlistViewModel: ObservableObject {
    
    @Published public var wishlistedApps: [SteamApp] = []
    @Published public var isLoading: Bool = false
    
    private let dataSource: SteamDBDataSource
    private let wishlistManager: WishlistManager
    
    public init(dataSource: SteamDBDataSource, wishlistManager: WishlistManager) {
        self.dataSource = dataSource
        self.wishlistManager = wishlistManager
    }
    
    public func loadWishlist() async {
        isLoading = true
        var apps: [SteamApp] = []
        
        for appID in wishlistManager.wishlist {
            if let app = try? await dataSource.fetchAppDetails(appID: appID) {
                apps.append(app)
            }
        }
        
        self.wishlistedApps = apps
        isLoading = false
    }
}
