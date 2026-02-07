import Foundation
import Combine

public enum SteamAuthState: String, Codable {
    case unknown
    case notSignedIn
    case signedIn
}

public enum WishlistSyncState: String, Codable {
    case idle
    case syncing
    case synced
    case failed
}

@MainActor
public class WishlistManager: ObservableObject {
    
    @Published public var wishlist: Set<Int> = []
    @Published public var steamAuthState: SteamAuthState = .unknown
    @Published public var syncState: WishlistSyncState = .idle
    @Published public var lastSyncAt: Date?
    @Published public var syncError: String?
    
    private let saveKey = "user_wishlist"
    private let lastSyncKey = "user_wishlist_last_sync_at"
    private let syncStateKey = "user_wishlist_sync_state"
    private let syncErrorKey = "user_wishlist_sync_error"
    private let authStateKey = "steam_auth_state"
    
    public init() {
        load()
    }
    
    public func toggleWishlist(appID: Int) {
        if wishlist.contains(appID) {
            wishlist.remove(appID)
        } else {
            wishlist.insert(appID)
        }
        save()
    }
    
    public func isWishlisted(appID: Int) -> Bool {
        wishlist.contains(appID)
    }

    public var isSteamSignedIn: Bool {
        steamAuthState == .signedIn
    }

    public func setSteamAuthState(_ state: SteamAuthState) {
        steamAuthState = state
        saveMetadata()
    }

    public func beginSync() {
        syncState = .syncing
        syncError = nil
        saveMetadata()
    }

    public func applySyncSuccess(appIDs: Set<Int>, syncedAt: Date = Date()) {
        wishlist = appIDs
        syncState = .synced
        syncError = nil
        lastSyncAt = syncedAt
        steamAuthState = .signedIn
        save()
        saveMetadata()
    }

    public func applySyncFailure(_ message: String, authenticated: Bool? = nil) {
        syncState = .failed
        syncError = message
        if let authenticated {
            steamAuthState = authenticated ? .signedIn : .notSignedIn
        }
        saveMetadata()
    }

    public func setWishlist(_ appIDs: Set<Int>) {
        wishlist = appIDs
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(wishlist) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func saveMetadata() {
        UserDefaults.standard.set(lastSyncAt, forKey: lastSyncKey)
        UserDefaults.standard.set(syncState.rawValue, forKey: syncStateKey)
        UserDefaults.standard.set(syncError, forKey: syncErrorKey)
        UserDefaults.standard.set(steamAuthState.rawValue, forKey: authStateKey)
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.wishlist = saved
        }

        if let rawSyncState = UserDefaults.standard.string(forKey: syncStateKey),
           let restoredSyncState = WishlistSyncState(rawValue: rawSyncState) {
            self.syncState = restoredSyncState
        }

        if let rawAuthState = UserDefaults.standard.string(forKey: authStateKey),
           let restoredAuthState = SteamAuthState(rawValue: rawAuthState) {
            self.steamAuthState = restoredAuthState
        }

        self.lastSyncAt = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        self.syncError = UserDefaults.standard.string(forKey: syncErrorKey)
    }
}
