import SwiftUI

@main
struct SteamDBCompanionApp: App {
    @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @StateObject private var alertEngine = InAppAlertEngine()
    
    // Use RealSteamDBDataSource for production
    private let dataSource: SteamDBDataSource = RealSteamDBDataSource()
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataSource: dataSource)
                .environmentObject(wishlistManager)
                .environmentObject(deepLinkRouter)
                .environmentObject(alertEngine)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
    }
}
