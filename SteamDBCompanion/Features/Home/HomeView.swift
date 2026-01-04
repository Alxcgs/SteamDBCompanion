import SwiftUI

public struct HomeView: View {
    
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject var wishlistManager: WishlistManager
    private let dataSource: SteamDBDataSource
    
    public init(dataSource: SteamDBDataSource) {
        self.dataSource = dataSource
        _viewModel = StateObject(wrappedValue: HomeViewModel(dataSource: dataSource))
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                GlassBackgroundView(material: .regularMaterial)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DeviceInfo.isIPad ? 32 : 24) {
                        // Header
                        HStack {
                            Text("SteamDB")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: WishlistView(dataSource: dataSource, wishlistManager: wishlistManager)) {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: SteamDBWebView()) {
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: SearchView(dataSource: dataSource)) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search")
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .frame(width: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LiquidGlassTheme.Layout.cornerRadius)
                                        .strokeBorder(Color.primary.opacity(0.5), lineWidth: 1)
                                )
                                .foregroundStyle(.primary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                Text("Loading...")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 20)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(0..<5, id: \.self) { _ in
                                        SkeletonAppCard()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else if let error = viewModel.errorMessage {
                            GlassCard {
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundStyle(LiquidGlassTheme.Colors.neonError)
                                    Text(error)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    GlassButton("Retry", style: .primary) {
                                        Task { await viewModel.loadData() }
                                    }
                                }
                            }
                            .padding()
                        } else {
                            // Trending Section
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Trending", icon: "chart.line.uptrend.xyaxis")
                                
                                if DeviceInfo.isIPad {
                                    // iPad: Grid layout
                                    LazyVGrid(
                                        columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2),
                                        spacing: 20
                                    ) {
                                        ForEach(viewModel.trendingApps) { app in
                                            NavigationLink(value: app) {
                                                TrendingAppCard(app: app)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                } else {
                                    // iPhone: Horizontal scroll
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.trendingApps) { app in
                                                TrendingAppCard(app: app)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // Top Sellers Section
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Top Sellers", icon: "crown.fill")
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.topSellers) { app in
                                        TopSellerRow(app: app)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Most Played Section
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Most Played", icon: "person.2.fill")

                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.mostPlayed) { app in
                                        TopSellerRow(app: app)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .task {
                await viewModel.loadData()
            }
            .navigationDestination(for: SteamApp.self) { app in
                AppDetailView(appID: app.id, dataSource: dataSource)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(LiquidGlassTheme.Colors.neonPrimary)
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
        }
        .padding(.horizontal)
    }
}

struct TrendingAppCard: View {
    let app: SteamApp
    
    var body: some View {
        NavigationLink(value: app) {
            GlassCard(padding: 0) {
                VStack(alignment: .leading) {
                    // Placeholder for game image
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "gamecontroller.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.2))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                        
                        if let price = app.price {
                            Text(price.formatted)
                                .font(.subheadline)
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                        } else {
                            Text("Free")
                                .font(.subheadline)
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                        }
                    }
                    .padding(12)
                }
                .frame(width: DeviceInfo.isIPad ? nil : 200)
                .frame(maxWidth: DeviceInfo.isIPad ? .infinity : nil)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TopSellerRow: View {
    let app: SteamApp
    
    var body: some View {
        NavigationLink(value: app) {
            GlassCard(padding: 12) {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "gamecontroller")
                                .foregroundStyle(.white.opacity(0.5))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                        
                        HStack {
                            if let players = app.playerStats {
                                Label("\(players.currentPlayers)", systemImage: "person.2.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if let price = app.price {
                        Text(price.formatted)
                            .font(.headline)
                            .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(LiquidGlassTheme.Colors.neonSuccess.opacity(0.1))
                            )
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeView(dataSource: MockSteamDBDataSource())
            .environmentObject(WishlistManager())
    }
}
