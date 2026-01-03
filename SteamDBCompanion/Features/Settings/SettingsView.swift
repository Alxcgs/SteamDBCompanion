import SwiftUI

public struct SettingsView: View {
    
    @StateObject private var notificationService = NotificationRegistrationService.shared
    @State private var showPermissionSheet = false
    
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
                                Text("Notifications")
                                    .font(.headline)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                Spacer()
                            }
                            
                            if notificationService.isAuthorized {
                                HStack {
                                    Text("Status")
                                    Spacer()
                                    Text("Active")
                                        .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                                }
                                .font(.subheadline)
                            } else {
                                GlassButton("Enable Notifications", style: .primary) {
                                    showPermissionSheet = true
                                }
                            }
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
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            NotificationPermissionView()
        }
    }
}

#Preview {
    SettingsView()
}
