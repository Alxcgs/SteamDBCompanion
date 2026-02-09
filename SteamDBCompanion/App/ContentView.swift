import SwiftUI

struct ContentView: View {
    
    let dataSource: SteamDBDataSource
    @AppStorage("fullWebsiteModeEnabled") private var fullWebsiteModeEnabled = false
    @AppStorage("steamStoreCountryCode") private var storeCountryCode = "auto"
    @AppStorage("steamStoreLanguageCode") private var storeLanguageCode = "en"
    @AppStorage("appLanguageMode") private var appLanguageModeRaw = AppLanguageMode.system.rawValue
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @EnvironmentObject private var wishlistManager: WishlistManager
    @EnvironmentObject private var alertEngine: InAppAlertEngine
    @Namespace private var toolbarNS

    var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            TabView {
                if fullWebsiteModeEnabled {
                    Group {
                        HomeView(dataSource: dataSource)
                    }
                    .tabItem {
                        Label(LocalizedStringKey("tab.home"), systemImage: "house.fill")
                    }

                    NavigationStack {
                        WebFallbackShellView(
                            url: URL(string: "https://steamdb.info/search/")!,
                            title: "Explore",
                            hidesTabBar: false,
                            showsNavigationChrome: false
                        )
                    }
                    .tabItem {
                        Label(LocalizedStringKey("tab.explore"), systemImage: "map.fill")
                    }
                } else {
                    HomeView(dataSource: dataSource)
                        .tabItem {
                            Label(LocalizedStringKey("tab.home"), systemImage: "house.fill")
                        }

                    NavigationStack {
                        RouteDirectoryView(dataSource: dataSource)
                    }
                    .tabItem {
                        Label(LocalizedStringKey("tab.explore"), systemImage: "map.fill")
                    }
                }

                if alertEngine.latestDiffs.isEmpty {
                    NavigationStack {
                        UpdatesView(dataSource: dataSource, wishlistManager: wishlistManager, alertEngine: alertEngine)
                    }
                    .tabItem {
                        Label(LocalizedStringKey("tab.updates"), systemImage: "bell.badge.fill")
                            .symbolEffect(.bounce, value: alertEngine.latestDiffs.count)
                    }
                } else {
                    NavigationStack {
                        UpdatesView(dataSource: dataSource, wishlistManager: wishlistManager, alertEngine: alertEngine)
                    }
                    .tabItem {
                        Label(LocalizedStringKey("tab.updates"), systemImage: "bell.badge.fill")
                            .symbolEffect(.bounce, value: alertEngine.latestDiffs.count)
                    }
                    .badge(alertEngine.latestDiffs.count)
                }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label(LocalizedStringKey("tab.settings"), systemImage: "gearshape.fill")
                }
                
                NavigationStack {
                    SearchView(dataSource: dataSource)
                }
                .tabItem {
                    Label(L10n.tr("tab.search", fallback: "Search"), systemImage: "magnifyingglass")
                }
            }
            .tint(LiquidGlassTheme.Colors.neonPrimary)
            .tabViewStyle(.automatic)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                                .buttonStyle(.glass)
                                .matchedTransitionSource(id: "deepLinkSheet", in: toolbarNS)
                            }
                        }
                        .navigationTransition(.zoom(sourceID: "deepLinkSheet", in: toolbarNS))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
        .onChange(of: fullWebsiteModeEnabled) { _, _ in
            // Reset search bar if needed
        }
        .id("tabs_\(fullWebsiteModeEnabled)_\(storeCountryCode)_\(storeLanguageCode)_\(appLanguageModeRaw)")
    }
}

#Preview {
    ContentView(dataSource: MockSteamDBDataSource())
        .environmentObject(WishlistManager())
        .environmentObject(DeepLinkRouter())
        .environmentObject(InAppAlertEngine())
}

