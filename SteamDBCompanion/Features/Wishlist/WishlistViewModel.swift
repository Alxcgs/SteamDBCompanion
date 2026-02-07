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
        steamSyncService: SteamWishlistSyncService? = nil
    ) {
        self.dataSource = dataSource
        self.wishlistManager = wishlistManager
        self.steamSyncService = steamSyncService ?? .shared
    }
    
    public func loadWishlist() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let session = await steamSyncService.checkSteamSession()
        wishlistManager.setSteamAuthState(session.isAuthenticated ? .signedIn : .notSignedIn)
        if let countryCode = session.countryCode {
            UserDefaults.standard.set(countryCode, forKey: "steamStoreCountryCode")
        }

        if session.isAuthenticated {
            await synchronizeWishlist(showAlert: false)
        } else {
            await loadAppDetailsFromStoredWishlist()
        }
    }

    public func syncFromSteamAccount() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        await synchronizeWishlist(showAlert: true)
    }

    private func synchronizeWishlist(showAlert: Bool) async {
        wishlistManager.beginSync()

        do {
            let result = try await steamSyncService.syncWishlist(into: wishlistManager)
            await loadAppDetailsFromStoredWishlist()

            if showAlert {
                syncAlertMessage = result.appIDs.isEmpty
                    ? L10n.tr("wishlist.sync_success_empty", fallback: "Steam wishlist synced. Your Steam wishlist is currently empty.")
                    : String(format: L10n.tr("wishlist.sync_success_count", fallback: "Steam wishlist synced: %d items."), result.appIDs.count)
                showSyncAlert = true
            }
        } catch {
            let isAuthError = error is SteamWishlistSyncError && (error as? SteamWishlistSyncError) == .notLoggedIn
            wishlistManager.applySyncFailure(error.localizedDescription, authenticated: !isAuthError)
            if isAuthError {
                wishlistManager.setSteamAuthState(.notSignedIn)
            }
            if showAlert {
                syncAlertMessage = error.localizedDescription
                showSyncAlert = true
            }
        }
    }

    private func loadAppDetailsFromStoredWishlist() async {
        var apps: [SteamApp] = []

        for appID in wishlistManager.wishlist.sorted() {
            if let app = try? await dataSource.fetchAppDetails(appID: appID) {
                apps.append(app)
            }
        }

        wishlistedApps = apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
