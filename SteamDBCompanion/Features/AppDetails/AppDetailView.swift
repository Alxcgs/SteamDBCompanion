import SwiftUI

public struct AppDetailView: View {
    
    @EnvironmentObject var wishlistManager: WishlistManager
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: AppDetailViewModel
    @State private var showStoreDestinationSheet = false
    @State private var openStoreInApp = false
    @State private var storeURL: URL?
    @State private var inAppWebTitle = "Steam"
    
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
                        if let imageURL = app.headerImageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "gamecontroller.fill")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.white.opacity(0.2))
                                        )
                                @unknown default:
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                }
                            }
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                        } else {
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
                        }
                        
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
                                StatCard(
                                    title: L10n.tr("app_detail.stat_current_players", fallback: "Current Players"),
                                    value: app.playerStats.map { Self.formatStatValue($0.currentPlayers) } ?? "—",
                                    icon: "person.2.fill"
                                )
                                StatCard(
                                    title: L10n.tr("app_detail.stat_peak_24h", fallback: "24h Peak"),
                                    value: app.playerStats.map { Self.formatStatValue($0.peak24h) } ?? "—",
                                    icon: "chart.bar.fill"
                                )
                                StatCard(
                                    title: L10n.tr("app_detail.stat_peak_all_time", fallback: "All-Time Peak"),
                                    value: app.playerStats.map { Self.formatStatValue($0.allTimePeak) } ?? "—",
                                    icon: "trophy.fill"
                                )
                                StatCard(
                                    title: L10n.tr("app_detail.stat_app_id", fallback: "App ID"),
                                    value: "\(app.id)",
                                    icon: "number"
                                )
                            }

                            if let shortDescription = app.shortDescription, !shortDescription.isEmpty {
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(L10n.tr("app_detail.description", fallback: "Description"))
                                            .font(.headline)
                                            .foregroundStyle(.secondary)
                                        Text(shortDescription)
                                            .font(.body)
                                            .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            // Platforms
                            GlassCard {
                                VStack(alignment: .leading) {
                                    Text(L10n.tr("app_detail.platforms", fallback: "Platforms"))
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
                            
                            // Price History Chart
                            if let history = viewModel.priceHistory {
                                NavigationLink {
                                    PriceHistoryDetailView(history: history, appName: app.name)
                                } label: {
                                    GlassCard {
                                        PriceHistoryChartView(history: history)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption.bold())
                                            .foregroundStyle(.secondary)
                                            .padding(8)
                                            .background(Color.black.opacity(0.12))
                                            .clipShape(Circle())
                                            .padding(12)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Player Trend Chart
                            if let trend = viewModel.playerTrend, !trend.points.isEmpty {
                                NavigationLink {
                                    PlayerTrendDetailView(trend: trend, appName: app.name)
                                } label: {
                                    GlassCard {
                                        PlayerTrendChartView(trend: trend)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption.bold())
                                            .foregroundStyle(.secondary)
                                            .padding(8)
                                            .background(Color.black.opacity(0.12))
                                            .clipShape(Circle())
                                            .padding(12)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Actions
                            HStack {
                                let isSteamSignedIn = wishlistManager.isSteamSignedIn
                                let isWishlisted = wishlistManager.isWishlisted(appID: app.id)
                                let wishlistTitle = !isSteamSignedIn
                                    ? L10n.tr("app_detail.sign_in_wishlist", fallback: "Sign in for Wishlist")
                                    : (isWishlisted
                                        ? L10n.tr("app_detail.in_wishlist", fallback: "In Wishlist")
                                        : L10n.tr("app_detail.manage_wishlist", fallback: "Manage in Steam"))
                                let wishlistIcon = isWishlisted ? "heart.fill" : "heart"

                                GlassButton(
                                    wishlistTitle,
                                    icon: wishlistIcon,
                                    style: isWishlisted ? .primary : .secondary
                                ) {
                                    if !isSteamSignedIn {
                                        storeURL = URL(string: "https://store.steampowered.com/login/")
                                        inAppWebTitle = L10n.tr("steam.sign_in", fallback: "Sign in with Steam")
                                        openStoreInApp = true
                                        return
                                    }

                                    if isWishlisted {
                                        storeURL = URL(string: "https://store.steampowered.com/wishlist/")
                                        inAppWebTitle = L10n.tr("wishlist.steam_title", fallback: "Steam Wishlist")
                                        openStoreInApp = true
                                    } else {
                                        storeURL = URL(string: "https://store.steampowered.com/app/\(app.id)/")
                                        showStoreDestinationSheet = true
                                    }
                                }
                                
                                GlassButton(L10n.tr("app_detail.store", fallback: "Store"), icon: "cart", style: .primary) {
                                    storeURL = URL(string: "https://store.steampowered.com/app/\(app.id)/")
                                    inAppWebTitle = L10n.tr("app_detail.store", fallback: "Store")
                                    showStoreDestinationSheet = true
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
        .navigationDestination(isPresented: $openStoreInApp) {
            if let storeURL {
                WebFallbackShellView(url: storeURL, title: inAppWebTitle)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showStoreDestinationSheet) {
            StoreOpenDestinationSheet(
                onInApp: {
                    guard storeURL != nil else { return }
                    openStoreInApp = true
                },
                onExternal: {
                    guard let storeURL else { return }
                    openURL(storeURL)
                }
            )
            .presentationDetents([.height(230)])
            .presentationDragIndicator(.visible)
        }
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

private extension AppDetailView {
    static func formatStatValue(_ value: Int) -> String {
        guard value > 0 else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
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

private struct StoreOpenDestinationSheet: View {
    let onInApp: () -> Void
    let onExternal: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.tr("store_sheet.title", fallback: "Open store page"))
                .font(.headline)
                .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)

            Text(L10n.tr("store_sheet.message", fallback: "Choose where to open the Steam store page."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                dismiss()
                onInApp()
            } label: {
                sheetActionRow(L10n.tr("store_sheet.open_in_app", fallback: "Open in app browser"), icon: "safari")
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
                onExternal()
            } label: {
                sheetActionRow(L10n.tr("store_sheet.open_external", fallback: "Open in external browser"), icon: "arrow.up.right.square")
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                sheetActionRow(L10n.tr("common.cancel", fallback: "Cancel"), icon: "xmark")
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    @ViewBuilder
    private func sheetActionRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
            Spacer()
        }
        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AppDetailView(appID: 730, dataSource: MockSteamDBDataSource())
        .environmentObject(WishlistManager())
}
