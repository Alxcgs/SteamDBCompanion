import SwiftUI

public struct SettingsView: View {
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.system.rawValue
    @AppStorage("appLanguageMode") private var appLanguageModeRaw = AppLanguageMode.system.rawValue
    @AppStorage("fullWebsiteModeEnabled") private var fullWebsiteModeEnabled = false
    @AppStorage("steamStoreCountryCode") private var storeCountryCode = "auto"
    @AppStorage("steamStoreLanguageCode") private var storeLanguageCode = "en"
    @EnvironmentObject private var wishlistManager: WishlistManager

    public init() {}
    
    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text(L10n.tr("settings.title", fallback: "Settings"))
                            .font(.largeTitle.bold())
                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Appearance
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "circle.lefthalf.filled")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                                Text(L10n.tr("settings.appearance", fallback: "Appearance"))
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Picker(L10n.tr("settings.theme", fallback: "Theme"), selection: $appAppearanceModeRaw) {
                                ForEach(AppAppearanceMode.allCases) { mode in
                                    Text(mode.title).tag(mode.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker(L10n.tr("settings.app_language", fallback: "App Language"), selection: $appLanguageModeRaw) {
                                ForEach(AppLanguageMode.allCases) { mode in
                                    Text(mode.title).tag(mode.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text(L10n.tr("settings.oled_dark_hint", fallback: "Dark mode uses OLED black."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Browsing
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                                Text(L10n.tr("settings.browsing_mode", fallback: "Browsing Mode"))
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Toggle(isOn: $fullWebsiteModeEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.tr("settings.full_website_toggle", fallback: "Use full website in app"))
                                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                    Text(L10n.tr("settings.full_website_hint", fallback: "When enabled, Home/Explore open full SteamDB web mode inside the app."))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            Text(L10n.tr("settings.full_website_default", fallback: "Default: disabled (native mode)."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Steam Account
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                                Text(L10n.tr("settings.steam_account", fallback: "Steam Account (In-App Web)"))
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            NavigationLink {
                                WebFallbackShellView(url: URL(string: "https://store.steampowered.com/login/")!, title: L10n.tr("steam.sign_in", fallback: "Sign in with Steam"))
                            } label: {
                                settingsLinkLabel(L10n.tr("steam.sign_in", fallback: "Sign in with Steam"), icon: "person.crop.circle.badge.plus")
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                WebFallbackShellView(url: URL(string: "https://store.steampowered.com/wishlist/")!, title: L10n.tr("wishlist.steam_title", fallback: "Steam Wishlist"))
                            } label: {
                                settingsLinkLabel(L10n.tr("settings.open_steam_wishlist", fallback: "Open Steam Wishlist"), icon: "heart.text.square")
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                WebFallbackShellView(url: URL(string: "https://store.steampowered.com/news/")!, title: L10n.tr("settings.open_steam_news", fallback: "Open Steam News"))
                            } label: {
                                settingsLinkLabel(L10n.tr("settings.open_steam_news", fallback: "Open Steam News"), icon: "newspaper")
                            }
                            .buttonStyle(.plain)

                            Text(L10n.tr("settings.steam_account_hint", fallback: "Personal pages and account currency are shown in web mode after login."))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Image(systemName: wishlistManager.isSteamSignedIn ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(wishlistManager.isSteamSignedIn ? LiquidGlassTheme.Colors.neonSuccess : LiquidGlassTheme.Colors.neonWarning)
                                Text(wishlistManager.isSteamSignedIn ? L10n.tr("wishlist.auth_signed_in", fallback: "Signed in to Steam") : L10n.tr("wishlist.auth_not_signed_in", fallback: "Not signed in"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if let syncDate = wishlistManager.lastSyncAt {
                                    Text(syncDate.formatted(date: .numeric, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Store Region
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "coloncurrencysign.circle")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
                                Text(L10n.tr("settings.store_region", fallback: "Store Region"))
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Picker(L10n.tr("settings.country", fallback: "Country"), selection: $storeCountryCode) {
                                Text(L10n.tr("settings.country_auto", fallback: "Auto")).tag("auto")
                                Text("US").tag("us")
                                Text("UA").tag("ua")
                                Text("PL").tag("pl")
                                Text("DE").tag("de")
                                Text("GB").tag("gb")
                                Text("TR").tag("tr")
                                Text("BR").tag("br")
                                Text("JP").tag("jp")
                            }
                            .pickerStyle(.menu)

                            Picker(L10n.tr("settings.store_content_language", fallback: "Store Content Language"), selection: $storeLanguageCode) {
                                Text(L10n.tr("language.english", fallback: "English")).tag("en")
                                Text(L10n.tr("language.ukrainian", fallback: "Ukrainian")).tag("uk")
                                Text(L10n.tr("language.polish", fallback: "Polish")).tag("pl")
                                Text(L10n.tr("language.german", fallback: "German")).tag("de")
                                Text(L10n.tr("language.turkish", fallback: "Turkish")).tag("tr")
                                Text(L10n.tr("language.japanese", fallback: "Japanese")).tag("ja")
                            }
                            .pickerStyle(.menu)

                            Text(L10n.tr("settings.store_content_language_hint", fallback: "Affects fetched store content and prices, not the app UI language."))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(L10n.tr("settings.store_region_hint", fallback: "Set this to your Steam account country for matching prices in native screens."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Notifications
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                                Text(L10n.tr("settings.in_app_alerts", fallback: "In-App Alerts"))
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Text(L10n.tr("settings.in_app_alerts_hint", fallback: "Price and player alerts run for wishlisted apps when you refresh or open the app."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text(L10n.tr("settings.mode", fallback: "Mode"))
                                Spacer()
                                Text(L10n.tr("settings.free_mode", fallback: "Free (No APNs)"))
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    // About
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
                                Text(L10n.tr("settings.about", fallback: "About"))
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }
                            
                            Text("SteamDB Companion v1.1")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(L10n.tr("settings.disclaimer_1", fallback: "This app is not affiliated with Valve or SteamDB."))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(L10n.tr("settings.disclaimer_2", fallback: "SteamDB Companion is unofficial and uses public data only."))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            NavigationLink {
                                WebFallbackShellView(url: URL(string: "https://steamdb.info/")!, title: "SteamDB")
                            } label: {
                                settingsLinkLabel(L10n.tr("settings.open_steamdb", fallback: "Open SteamDB"), icon: "safari")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: storeCountryCode) { _, _ in
            Task { await CacheService.shared.clearCache() }
        }
        .onChange(of: storeLanguageCode) { _, _ in
            Task { await CacheService.shared.clearCache() }
        }
        .onChange(of: appLanguageModeRaw) { _, _ in
            // UI language is independent from store content language.
        }
        .task {
            let session = await SteamWishlistSyncService.shared.checkSteamSession()
            wishlistManager.setSteamAuthState(session.isAuthenticated ? .signedIn : .notSignedIn)
        }
    }

    @ViewBuilder
    private func settingsLinkLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
            Text(title)
                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SettingsView()
}
