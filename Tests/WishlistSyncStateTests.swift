import XCTest
@testable import SteamDBCompanion

@MainActor
final class WishlistSyncStateTests: XCTestCase {
    private var manager: WishlistManager!

    override func setUp() {
        super.setUp()
        clearStoredState()
        manager = WishlistManager()
    }

    override func tearDown() {
        clearStoredState()
        manager = nil
        super.tearDown()
    }

    func testBeginSyncAndFailureState() {
        manager.beginSync()
        XCTAssertEqual(manager.syncState, .syncing)
        XCTAssertNil(manager.syncError)

        manager.applySyncFailure("network issue", authenticated: false)
        XCTAssertEqual(manager.syncState, .failed)
        XCTAssertEqual(manager.syncError, "network issue")
        XCTAssertEqual(manager.steamAuthState, .notSignedIn)
    }

    func testApplySyncSuccessStoresMetadata() {
        let now = Date()
        manager.applySyncSuccess(appIDs: [730, 570], syncedAt: now)

        XCTAssertEqual(manager.syncState, .synced)
        XCTAssertEqual(manager.steamAuthState, .signedIn)
        XCTAssertEqual(manager.wishlist, Set([730, 570]))
        XCTAssertEqual(manager.lastSyncAt?.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertNil(manager.syncError)
    }

    private func clearStoredState() {
        let defaults = UserDefaults.standard
        [
            "user_wishlist",
            "user_wishlist_last_sync_at",
            "user_wishlist_sync_state",
            "user_wishlist_sync_error",
            "steam_auth_state"
        ].forEach { defaults.removeObject(forKey: $0) }
    }
}

