import SwiftUI

// Helper views for iPad two-column layout
struct AppDetailContent: View {
    let app: SteamApp
    @ObservedObject var viewModel: AppDetailViewModel
    @ObservedObject var wishlistManager: WishlistManager
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 16) {
            // Price
            if let price = app.price {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(price.formatted)
                                .font(.title2.bold())
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                        }
                        Spacer()
                        if price.discountPercent > 0 {
                            Text("-\(price.discountPercent)%")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LiquidGlassTheme.Colors.neonSuccess)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            
            // Player Stats
            if let stats = app.playerStats {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Players")
                            .font(.headline)
                        HStack(spacing: 20) {
                            StatItem(label: "Now", value: "\(stats.currentPlayers)", icon: "person.2.fill")
                            StatItem(label: "24h Peak", value: "\(stats.peak24h)", icon: "arrow.up.right")
                            StatItem(label: "All-Time", value: "\(stats.allTimePeak)", icon: "crown.fill")
                        }
                    }
                }
            }
            
            // Platforms
            if !app.platforms.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platforms")
                            .font(.headline)
                        HStack(spacing: 12) {
                            ForEach(app.platforms, id: \.self) { platform in
                                Label(platform.rawValue, systemImage: platform.icon)
                                    .font(.caption)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Price History
            if let history = viewModel.priceHistory {
                GlassCard {
                    PriceHistoryChartView(history: history)
                }
            }
            
            // Player Trend
            if let trend = viewModel.playerTrend, !trend.points.isEmpty {
                GlassCard {
                    PlayerTrendChartView(trend: trend)
                }
            }
            
            // Actions
            HStack {
                let isWishlisted = wishlistManager.isWishlisted(appID: app.id)
                GlassButton(isWishlisted ? "In Wishlist" : "Wishlist",
                          icon: isWishlisted ? "heart.fill" : "heart",
                          style: isWishlisted ? .primary : .secondary) {
                    wishlistManager.toggleWishlist(appID: app.id)
                    HapticManager.shared.notification(isWishlisted ? .success : .warning)
                }
                
                GlassButton("Store", icon: "cart", style: .primary) {
                    if let storeURL = URL(string: "https://store.steampowered.com/app/\(app.id)/") {
                        openURL(storeURL)
                    }
                }
            }
        }
    }
}

// Left column for iPad
struct AppDetailLeftColumn: View {
    let app: SteamApp
    @ObservedObject var viewModel: AppDetailViewModel
    @ObservedObject var wishlistManager: WishlistManager
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Group {
            // Price
            if let price = app.price {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(price.formatted)
                                .font(.title2.bold())
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                        }
                        Spacer()
                        if price.discountPercent > 0 {
                            Text("-\(price.discountPercent)%")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LiquidGlassTheme.Colors.neonSuccess)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            
            // Player Stats
            if let stats = app.playerStats {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Players")
                            .font(.headline)
                        VStack(spacing: 12) {
                            StatItem(label: "Now", value: "\(stats.currentPlayers)", icon: "person.2.fill")
                            StatItem(label: "24h Peak", value: "\(stats.peak24h)", icon: "arrow.up.right")
                            StatItem(label: "All-Time", value: "\(stats.allTimePeak)", icon: "crown.fill")
                        }
                    }
                }
            }
            
            // Actions
            VStack(spacing: 12) {
                let isWishlisted = wishlistManager.isWishlisted(appID: app.id)
                GlassButton(isWishlisted ? "In Wishlist" : "Wishlist",
                          icon: isWishlisted ? "heart.fill" : "heart",
                          style: isWishlisted ? .primary : .secondary) {
                    wishlistManager.toggleWishlist(appID: app.id)
                    HapticManager.shared.notification(isWishlisted ? .success : .warning)
                }
                
                GlassButton("View in Steam Store", icon: "cart", style: .primary) {
                    if let storeURL = URL(string: "https://store.steampowered.com/app/\(app.id)/") {
                        openURL(storeURL)
                    }
                }
            }
        }
    }
}

// Right column for iPad (charts)
struct AppDetailRightColumn: View {
    @ObservedObject var viewModel: AppDetailViewModel
    
    var body: some View {
        Group {
            if let history = viewModel.priceHistory {
                GlassCard {
                    PriceHistoryChartView(history: history)
                }
            }
            
            if let trend = viewModel.playerTrend, !trend.points.isEmpty {
                GlassCard {
                    PlayerTrendChartView(trend: trend)
                }
            }
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
        }
    }
}
