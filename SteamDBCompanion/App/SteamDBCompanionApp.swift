import SwiftUI

@main
struct SteamDBCompanionApp: App {
    @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @StateObject private var alertEngine = InAppAlertEngine()
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.system.rawValue
    
    // Use RealSteamDBDataSource for production
    private let dataSource: SteamDBDataSource = RealSteamDBDataSource()

    private var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode.from(rawValue: appAppearanceModeRaw)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataSource: dataSource)
                .environmentObject(wishlistManager)
                .environmentObject(deepLinkRouter)
                .environmentObject(alertEngine)
                .preferredColorScheme(appAppearanceMode.colorScheme)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
    }
}
