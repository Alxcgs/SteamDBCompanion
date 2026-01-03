import SwiftUI

@main
struct SteamDBCompanionApp: App {
    @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var pushManager = PushNotificationManager()
    
    // Use RealSteamDBDataSource for production
    private let dataSource: SteamDBDataSource = RealSteamDBDataSource()
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataSource: dataSource)
                .environmentObject(wishlistManager)
                .onAppear {
                    pushManager.requestAuthorization()
                }
        }
    }
}
