import SwiftUI

@main
struct SteamDBCompanionApp: App {
    @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @StateObject private var alertEngine = InAppAlertEngine()
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguageMode") private var appLanguageModeRaw = AppLanguageMode.system.rawValue
    
    // Use RealSteamDBDataSource for production
    private let dataSource: SteamDBDataSource = RealSteamDBDataSource()

    private var appAppearanceMode: AppAppearanceMode {
        AppAppearanceMode.from(rawValue: appAppearanceModeRaw)
    }

    private var appLanguageMode: AppLanguageMode {
        AppLanguageMode.from(rawValue: appLanguageModeRaw)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataSource: dataSource)
                .environmentObject(wishlistManager)
                .environmentObject(deepLinkRouter)
                .environmentObject(alertEngine)
                .preferredColorScheme(appAppearanceMode.colorScheme)
                .environment(\.locale, appLanguageMode.locale ?? .autoupdatingCurrent)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
    }
}
