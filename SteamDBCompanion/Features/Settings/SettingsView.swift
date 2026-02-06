import SwiftUI

public struct SettingsView: View {
    @Environment(\.openURL) private var openURL

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
                            
                            Text("SteamDB Companion v1.0")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("This app is not affiliated with Valve or SteamDB.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("SteamDB Companion is unofficial and uses public data only.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            GlassButton("Open SteamDB Login in Safari", icon: "safari", style: .secondary) {
                                guard let loginURL = URL(string: "https://steamdb.info/login/") else { return }
                                openURL(loginURL)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
