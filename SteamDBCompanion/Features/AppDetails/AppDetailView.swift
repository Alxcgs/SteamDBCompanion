import SwiftUI

public struct AppDetailView: View {
    
    @EnvironmentObject var wishlistManager: WishlistManager
    @StateObject private var viewModel: AppDetailViewModel
    
    public init(appID: Int, dataSource: SteamDBDataSource) {
        _viewModel = StateObject(wrappedValue: AppDetailViewModel(appID: appID, dataSource: dataSource))
    }
    
    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(LiquidGlassTheme.Colors.neonError)
            } else if let app = viewModel.app {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Image
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.2))
                            )
                            .overlay(
                                LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                        
                        VStack(alignment: .leading, spacing: 24) {
                            // Title & Price
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text(app.name)
                                        .font(.title.bold())
                                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                    
                                    Text(app.type.rawValue.uppercased())
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(LiquidGlassTheme.Colors.neonPrimary.opacity(0.2))
                                        .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                                        .clipShape(Capsule())
                                }
                                
                                Spacer()
                                
                                if let price = app.price {
                                    VStack(alignment: .trailing) {
                                        Text(price.formatted)
                                            .font(.title2.bold())
                                            .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                                        
                                        if price.discountPercent > 0 {
                                            Text("-\(price.discountPercent)%")
                                                .font(.headline)
                                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(LiquidGlassTheme.Colors.neonSuccess.opacity(0.2))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                    }
                                }
                            }
                            
                            // Stats Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                StatCard(title: "Current Players", value: "\(app.playerStats?.currentPlayers ?? 0)", icon: "person.2.fill")
                                StatCard(title: "24h Peak", value: "\(app.playerStats?.peak24h ?? 0)", icon: "chart.bar.fill")
                                StatCard(title: "All-Time Peak", value: "\(app.playerStats?.allTimePeak ?? 0)", icon: "trophy.fill")
                                StatCard(title: "App ID", value: "\(app.id)", icon: "number")
                            }
                            
                            // Platforms
                            GlassCard {
                                VStack(alignment: .leading) {
                                    Text("Platforms")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 16) {
                                        ForEach(app.platforms, id: \.self) { platform in
                                            HStack {
                                                Image(systemName: platformIcon(for: platform))
                                                Text(platform.rawValue.capitalized)
                                            }
                                            .padding(8)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if app.developer != nil || app.publisher != nil || app.releaseDate != nil {
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Details")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)

                                        if let developer = app.developer, !developer.isEmpty {
                                            DetailRow(label: "Developer", value: developer)
                                        }

                                        if let publisher = app.publisher, !publisher.isEmpty {
                                            DetailRow(label: "Publisher", value: publisher)
                                        }

                                        if let date = app.releaseDate {
                                            DetailRow(label: "Release Date", value: date.formatted(date: .abbreviated, time: .omitted))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // Price History Chart
                            if let history = viewModel.priceHistory, !history.points.isEmpty {
                                GlassCard {
                                    PriceHistoryChartView(history: history)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            // Player Trend Chart
                            if let trend = viewModel.playerTrend, !trend.points.isEmpty {
                                GlassCard {
                                    PlayerTrendChartView(trend: trend)
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            // Explore Sections
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Explore")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)

                                    NavigationLink {
                                        ChartsView(priceHistory: viewModel.priceHistory, playerTrend: viewModel.playerTrend)
                                    } label: {
                                        SectionRow(title: "Charts", subtitle: "Price history & player trends", icon: "chart.line.uptrend.xyaxis")
                                    }

                                    NavigationLink {
                                        PackagesView(packages: viewModel.packages)
                                    } label: {
                                        SectionRow(title: "Packages", subtitle: "\(viewModel.packages.count) packages", icon: "shippingbox.fill")
                                    }

                                    NavigationLink {
                                        DepotsView(depots: viewModel.depots)
                                    } label: {
                                        SectionRow(title: "Depots", subtitle: "\(viewModel.depots.count) depots", icon: "tray.full.fill")
                                    }

                                    NavigationLink {
                                        BadgesView(badges: viewModel.badges)
                                    } label: {
                                        SectionRow(title: "Badges", subtitle: "\(viewModel.badges.count) badges", icon: "seal.fill")
                                    }

                                    NavigationLink {
                                        ChangelogView(entries: viewModel.changelogs)
                                    } label: {
                                        SectionRow(title: "Changelogs", subtitle: "\(viewModel.changelogs.count) entries", icon: "clock.arrow.circlepath")
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    // Open store
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetails()
        }
    }
    
    func platformIcon(for platform: Platform) -> String {
        switch platform {
        case .windows: return "desktopcomputer"
        case .mac: return "apple.logo"
        case .linux: return "penguin" // SF Symbols doesn't have penguin, fallback
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                    Spacer()
                }
                
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
            Spacer()
        }
    }
}

struct SectionRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    AppDetailView(appID: 730, dataSource: MockSteamDBDataSource())
        .environmentObject(WishlistManager())
}
