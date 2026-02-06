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
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer()
                            
                            NavigationLink(destination: WishlistView(dataSource: dataSource, wishlistManager: wishlistManager)) {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
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

                                if viewModel.trendingApps.isEmpty {
                                    Text("No trending data right now.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)
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

                                if viewModel.topSellers.isEmpty {
                                    Text("No top-seller data right now.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .task {
                await viewModel.refreshIfStale(maxAge: 0)
            }
            .onAppear {
                Task {
                    await viewModel.refreshIfStale(maxAge: 300)
                }
            }
            .refreshable {
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
    private let capsuleAspectRatio: CGFloat = 184.0 / 69.0
    
    var body: some View {
        NavigationLink(value: app) {
            GlassCard(padding: 0) {
                VStack(alignment: .leading) {
                    SteamCapsuleImage(imageURL: app.headerImageURL, cornerRadius: 0)
                        .aspectRatio(capsuleAspectRatio, contentMode: .fit)
                    
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
    private let rowImageSize = CGSize(width: 112, height: 42)
    
    var body: some View {
        NavigationLink(value: app) {
            GlassCard(padding: 12) {
                HStack {
                    SteamCapsuleImage(imageURL: app.headerImageURL, cornerRadius: 8)
                        .frame(width: rowImageSize.width, height: rowImageSize.height)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

                        HStack {
                            if let players = app.playerStats {
                                Label(formatNumber(players.currentPlayers), systemImage: "person.2.fill")
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

    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private struct SteamCapsuleImage: View {
    let imageURL: URL?
    let cornerRadius: CGFloat

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.3))
            case let .success(image):
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.black.opacity(0.3))
                    image
                        .resizable()
                        .scaledToFill()
                }
            case .failure:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Image(systemName: "gamecontroller.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.2))
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.3))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    NavigationStack {
        HomeView(dataSource: MockSteamDBDataSource())
            .environmentObject(WishlistManager())
    }
}
