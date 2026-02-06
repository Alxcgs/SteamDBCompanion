import SwiftUI

public struct SettingsView: View {
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.system.rawValue
    @AppStorage("fullWebsiteModeEnabled") private var fullWebsiteModeEnabled = false
    @AppStorage("steamStoreCountryCode") private var storeCountryCode = "auto"
    @AppStorage("steamStoreLanguageCode") private var storeLanguageCode = "en"

    public init() {}
    
    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Settings")
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
                                Text("Appearance")
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Picker("Theme", selection: $appAppearanceModeRaw) {
                                ForEach(AppAppearanceMode.allCases) { mode in
                                    Text(mode.title).tag(mode.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Dark mode uses OLED black.")
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
                                Text("Browsing Mode")
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Toggle(isOn: $fullWebsiteModeEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Use full website in app")
                                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                    Text("When enabled, Home/Explore open full SteamDB web mode inside the app.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            Text("Default: disabled (native mode).")
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
                                Text("Steam Account (In-App Web)")
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            NavigationLink {
                                WebFallbackShellView(url: URL(string: "https://store.steampowered.com/login/")!, title: "Sign in with Steam")
                            } label: {
                                settingsLinkLabel("Sign in with Steam", icon: "person.crop.circle.badge.plus")
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                WebFallbackShellView(url: URL(string: "https://store.steampowered.com/wishlist/")!, title: "Steam Wishlist")
                            } label: {
                                settingsLinkLabel("Open Steam Wishlist", icon: "heart.text.square")
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                WebFallbackShellView(url: URL(string: "https://store.steampowered.com/news/")!, title: "Steam News")
                            } label: {
                                settingsLinkLabel("Open Steam News", icon: "newspaper")
                            }
                            .buttonStyle(.plain)

                            Text("Personal pages and account currency are shown in web mode after login.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Store Region
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "coloncurrencysign.circle")
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
                                Text("Store Region")
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Picker("Country", selection: $storeCountryCode) {
                                Text("Auto").tag("auto")
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

                            Picker("Language", selection: $storeLanguageCode) {
                                Text("English").tag("en")
                                Text("Ukrainian").tag("uk")
                                Text("Polish").tag("pl")
                                Text("German").tag("de")
                                Text("Turkish").tag("tr")
                                Text("Japanese").tag("ja")
                            }
                            .pickerStyle(.menu)

                            Text("Set this to your Steam account country for matching prices in native screens.")
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
                                Text("In-App Alerts")
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }

                            Text("Price and player alerts run for wishlisted apps when you refresh or open the app.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("Mode")
                                Spacer()
                                Text("Free (No APNs)")
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
                                Text("About")
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }
                            
                            Text("SteamDB Companion v1.1")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("This app is not affiliated with Valve or SteamDB.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("SteamDB Companion is unofficial and uses public data only.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            NavigationLink {
                                WebFallbackShellView(path: "/", title: "SteamDB")
                            } label: {
                                settingsLinkLabel("Open SteamDB", icon: "safari")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
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
