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
    @State private var useNativeHomeFallback = false
    @State private var showWebFallbackBanner = false
    
    var body: some View {
        TabView {
            if fullWebsiteModeEnabled {
                Group {
                    if useNativeHomeFallback {
                        HomeView(dataSource: dataSource)
                            .safeAreaInset(edge: .top) {
                                if showWebFallbackBanner {
                                    HStack(spacing: 10) {
                                        Image(systemName: "wifi.exclamationmark")
                                        Text(L10n.tr("web.startup_fallback_banner", fallback: "Web mode is temporarily unavailable. Showing native Home."))
                                            .font(.caption)
                                        Spacer()
                                        Button(L10n.tr("common.retry", fallback: "Retry")) {
                                            useNativeHomeFallback = false
                                            showWebFallbackBanner = false
                                        }
                                        .font(.caption.bold())
                                        Button {
                                            showWebFallbackBanner = false
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption.bold())
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(.white)
                                    .background(Color.orange.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 8)
                                }
                            }
                    } else {
                        NavigationStack {
                            WebFallbackShellView(
                                url: URL(string: "https://steamdb.info/")!,
                                title: "SteamDB",
                                hidesTabBar: false,
                                showsNavigationChrome: false
                            ) {
                                guard fullWebsiteModeEnabled else { return }
                                useNativeHomeFallback = true
                                showWebFallbackBanner = true
                            }
                        }
                    }
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

            NavigationStack {
                UpdatesView(dataSource: dataSource, wishlistManager: wishlistManager, alertEngine: alertEngine)
            }
            .tabItem {
                Label(LocalizedStringKey("tab.updates"), systemImage: "bell.badge.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(LocalizedStringKey("tab.settings"), systemImage: "gearshape.fill")
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
        .onChange(of: fullWebsiteModeEnabled) { _, enabled in
            if enabled {
                useNativeHomeFallback = false
                showWebFallbackBanner = false
            } else {
                useNativeHomeFallback = false
                showWebFallbackBanner = false
            }
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
