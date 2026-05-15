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
                        HStack(alignment: .center, spacing: 12) {
                            Text("SteamDB")
                                .font(.largeTitle.bold())
                                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Spacer()

                            HStack(spacing: 12) {
                                NavigationLink(destination: WishlistView(dataSource: dataSource, wishlistManager: wishlistManager)) {
                                    WishlistHeartBubble(count: wishlistManager.wishlist.count)
                                        .accessibilityLabel(Text(L10n.tr("wishlist.title", fallback: "Wishlist")))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                Text(L10n.tr("common.loading", fallback: "Loading..."))
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 20)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(0..<5, id: \.self) { _ in
                                        SkeletonAppCard()
                                    }
                                }
                                .padding(.horizontal, 16)
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
                                    GlassButton(L10n.tr("common.retry", fallback: "Retry"), style: .primary) {
                                        Task { await viewModel.loadData() }
                                    }
                                }
                            }
                            .padding()
                        } else {
                            // Trending Section
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: L10n.tr("home.trending", fallback: "Trending"), icon: "chart.line.uptrend.xyaxis")
                                
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
                                } else {
                                    ScrollView(.horizontal) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.trendingApps) { app in
                                                NavigationLink(value: app) {
                                                    TrendingAppCard(app: app)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .scrollIndicators(.hidden)
                                }

                                if viewModel.trendingApps.isEmpty {
                                    Text(L10n.tr("home.no_trending", fallback: "No trending data right now."))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Top Sellers Section
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: L10n.tr("home.top_sellers", fallback: "Top Sellers"), icon: "crown.fill")
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.topSellers) { app in
                                        TopSellerRow(app: app)
                                    }
                                }

                                if viewModel.topSellers.isEmpty {
                                    Text(L10n.tr("home.no_top_sellers", fallback: "No top-seller data right now."))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
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
    }
}

struct TrendingAppCard: View {
    let app: SteamApp
    private let capsuleAspectRatio: CGFloat = 184.0 / 69.0
    
    var body: some View {
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
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(LiquidGlassTheme.Colors.neonSuccess.opacity(0.22), in: Capsule())
                    } else {
                        Text(L10n.tr("common.free", fallback: "Free"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(LiquidGlassTheme.Colors.neonSuccess.opacity(0.22), in: Capsule())
                    }
                }
                .padding(12)
            }
            .frame(width: DeviceInfo.isIPad ? nil : 200)
            .frame(maxWidth: DeviceInfo.isIPad ? .infinity : nil)
        }
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
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(LiquidGlassTheme.Colors.neonSuccess.opacity(0.22), in: Capsule())
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

private struct WishlistHeartBubble: View {
    let count: Int
    var body: some View {
        let hasItems = count > 0
        return Image(systemName: hasItems ? "heart.fill" : "heart")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
            .frame(width: 36, height: 36)
            .background(LiquidGlassTheme.Colors.neonSecondary.opacity(0.22), in: Circle())
            .overlay(alignment: .topTrailing) {
                if hasItems {
                    Text(String(min(count, 99)))
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(LiquidGlassTheme.Colors.neonSecondary)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -6)
                }
            }
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        HomeView(dataSource: MockSteamDBDataSource())
            .environmentObject(WishlistManager())
    }
}
