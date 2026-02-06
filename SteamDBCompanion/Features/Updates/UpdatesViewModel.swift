import Foundation
import Combine

@MainActor
public final class UpdatesViewModel: ObservableObject {
    @Published public var trackedApps: [SteamApp] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private let dataSource: SteamDBDataSource
    private let wishlistManager: WishlistManager
    private let alertEngine: InAppAlertEngine

    public init(
        dataSource: SteamDBDataSource,
        wishlistManager: WishlistManager,
        alertEngine: InAppAlertEngine
    ) {
        self.dataSource = dataSource
        self.wishlistManager = wishlistManager
        self.alertEngine = alertEngine
    }

    public func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var apps: [SteamApp] = []
            for appID in wishlistManager.wishlist.sorted() {
                let app = try await dataSource.fetchAppDetails(appID: appID)
                apps.append(app)
            }

            trackedApps = apps
            alertEngine.refresh(apps: apps)
        } catch {
            errorMessage = "Failed to refresh updates: \(error.localizedDescription)"
        }
    }
}
