import SwiftUI

struct ContentView: View {
    
    let dataSource: SteamDBDataSource
    @AppStorage("fullWebsiteModeEnabled") private var fullWebsiteModeEnabled = false
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @EnvironmentObject private var wishlistManager: WishlistManager
    @EnvironmentObject private var alertEngine: InAppAlertEngine
    
    var body: some View {
        TabView {
            if fullWebsiteModeEnabled {
                NavigationStack {
                    WebFallbackShellView(url: URL(string: "https://steamdb.info/")!, title: "SteamDB")
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

                NavigationStack {
                    WebFallbackShellView(url: URL(string: "https://steamdb.info/search/")!, title: "Explore")
                }
                .tabItem {
                    Label("Explore", systemImage: "map.fill")
                }
            } else {
                HomeView(dataSource: dataSource)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                NavigationStack {
                    RouteDirectoryView(dataSource: dataSource)
                }
                .tabItem {
                    Label("Explore", systemImage: "map.fill")
                }
            }

            NavigationStack {
                UpdatesView(dataSource: dataSource, wishlistManager: wishlistManager, alertEngine: alertEngine)
            }
            .tabItem {
                Label("Updates", systemImage: "bell.badge.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .sheet(isPresented: Binding(
            get: { deepLinkRouter.presentedPath != nil },
            set: { isPresented in
                if !isPresented {
                    deepLinkRouter.dismiss()
                }
            }
        )) {
            if let path = deepLinkRouter.presentedPath {
                NavigationStack {
                    RouteHostView(path: path, dataSource: dataSource)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    deepLinkRouter.dismiss()
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    ContentView(dataSource: MockSteamDBDataSource())
        .environmentObject(WishlistManager())
        .environmentObject(DeepLinkRouter())
        .environmentObject(InAppAlertEngine())
}
