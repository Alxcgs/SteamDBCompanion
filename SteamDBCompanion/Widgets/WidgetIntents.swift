import AppIntents
import Foundation

// MARK: - App Intents for Interactive Widgets (iOS 17+)

struct ToggleWishlistIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Wishlist"
    static var description = IntentDescription("Add or remove a game from your wishlist")
    
    @Parameter(title: "App ID")
    var appID: Int
    
    @Parameter(title: "App Name")
    var appName: String
    
    init() {}
    
    init(appID: Int, appName: String) {
        self.appID = appID
        self.appName = appName
    }
    
    func perform() async throws -> some IntentResult {
        // Access WishlistManager through shared container
        let manager = WishlistManager()
        
        await MainActor.run {
            manager.toggleWishlist(appID: appID)
        }
        
        let isWishlisted = await MainActor.run {
            manager.isWishlisted(appID: appID)
        }
        
        let message = isWishlisted ? "Added \(appName) to wishlist" : "Removed \(appName) from wishlist"
        
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct RefreshDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Data"
    static var description = IntentDescription("Refresh trending games data")
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        // Trigger widget timeline reload
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result(dialog: "Data refreshed")
    }
}

struct OpenGameDetailsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Game"
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "App ID")
    var appID: Int
    
    init() {}
    
    init(appID: Int) {
        self.appID = appID
    }
    
    func perform() async throws -> some IntentResult {
        // Deep link handled by app
        return .result()
    }
}

// MARK: - App Shortcuts

struct SteamDBShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RefreshDataIntent(),
            phrases: [
                "Refresh \(.applicationName) data",
                "Update Steam trending in \(.applicationName)"
            ],
            shortTitle: "Refresh Data",
            systemImageName: "arrow.clockwise"
        )
    }
}
