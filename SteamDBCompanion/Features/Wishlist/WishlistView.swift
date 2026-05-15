import SwiftUI

public struct WishlistView: View {
    
    @EnvironmentObject var wishlistManager: WishlistManager
    @StateObject private var viewModel: WishlistViewModel
    private let dataSource: SteamDBDataSource
    
    public init(dataSource: SteamDBDataSource, wishlistManager: WishlistManager) {
        self.dataSource = dataSource
        _viewModel = StateObject(wrappedValue: WishlistViewModel(dataSource: dataSource, wishlistManager: wishlistManager))
    }
    
    public var body: some View {
        ZStack {
            GlassBackgroundView(material: .regularMaterial)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                statusCard
                    .padding(.horizontal)
                    .padding(.top, 6)

                if viewModel.isRefreshing {
                    ProgressView(L10n.tr("wishlist.refreshing", fallback: "Refreshing wishlist..."))
                        .font(.caption)
                        .padding(.top, 2)
                }

                if viewModel.isLoading {
                    Spacer()
                    ContentStatusView(
                        kind: .loading,
                        title: L10n.tr("wishlist.syncing", fallback: "Syncing Steam wishlist..."),
                        message: L10n.tr("wishlist.syncing_hint", fallback: "Checking your Steam session and loading app details.")
                    )
                    Spacer()
                } else if !wishlistManager.isSteamSignedIn {
                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 56))
                            .foregroundStyle(.secondary)

                        Text(L10n.tr("wishlist.not_signed_in_title", fallback: "Not signed in to Steam"))
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)

                        Text(L10n.tr("wishlist.not_signed_in_message", fallback: "Sign in with Steam to load your account wishlist."))
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        NavigationLink {
                            WebFallbackShellView(url: AppURLs.steamStoreLogin, title: L10n.tr("steam.sign_in", fallback: "Sign in with Steam"))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text(L10n.tr("steam.sign_in", fallback: "Sign in with Steam"))
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task { await viewModel.loadWishlist() }
                        } label: {
                            Text(L10n.tr("common.retry", fallback: "Retry"))
                                .font(.callout.weight(.semibold))
                        }
                    }
                    .padding(.top, 40)
                    Spacer()
                } else if viewModel.wishlistedApps.isEmpty {
                    VStack(spacing: 14) {
                        ContentStatusView(
                            kind: .empty,
                            title: L10n.tr("wishlist.empty_steam", fallback: "Your Steam wishlist is empty"),
                            message: L10n.tr("wishlist.empty_steam_hint", fallback: "Open your Steam wishlist in web mode or refresh after adding games.")
                        )
                        NavigationLink {
                            WebFallbackShellView(url: AppURLs.steamStoreWishlist, title: L10n.tr("wishlist.steam_title", fallback: "Steam Wishlist"))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.text.square")
                                Text(L10n.tr("wishlist.open_web", fallback: "Open Steam Wishlist (Web)"))
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 40)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if let partialLoadMessage = viewModel.partialLoadMessage {
                                ContentStatusView(
                                    kind: .info,
                                    title: L10n.tr("wishlist.partial_title", fallback: "Partially loaded"),
                                    message: partialLoadMessage,
                                    actionTitle: L10n.tr("common.retry", fallback: "Retry")
                                ) {
                                    Task { await viewModel.loadWishlist() }
                                }
                            }

                            ForEach(viewModel.wishlistedApps) { app in
                                NavigationLink {
                                    AppDetailView(appID: app.id, dataSource: dataSource)
                                } label: {
                                    WishlistRow(app: app)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 18)
                    }
                }
            }
        }
        .navigationTitle(L10n.tr("wishlist.title", fallback: "Wishlist"))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    WebFallbackShellView(url: AppURLs.steamStoreLogin, title: L10n.tr("steam.sign_in", fallback: "Sign in with Steam"))
                } label: {
                    Image(systemName: "person.crop.circle.badge.plus")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.syncFromSteamAccount() }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    WebFallbackShellView(url: AppURLs.steamStoreWishlist, title: L10n.tr("wishlist.steam_title", fallback: "Steam Wishlist"))
                } label: {
                    Image(systemName: "safari")
                }
            }
        }
        .alert(L10n.tr("wishlist.sync_alert_title", fallback: "Steam Sync"), isPresented: $viewModel.showSyncAlert) {
            Button(L10n.tr("common.ok", fallback: "OK"), role: .cancel) {}
        } message: {
            Text(viewModel.syncAlertMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadWishlist()
            }
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label {
                        Text(authStatusTitle)
                    } icon: {
                        Image(systemName: authStatusIcon)
                    }
                    .foregroundStyle(authStatusColor)
                    .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(syncStateLabel)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                if let lastSyncAt = wishlistManager.lastSyncAt {
                    Text("\(L10n.tr("wishlist.last_sync", fallback: "Last sync")): \(lastSyncAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let syncError = wishlistManager.syncError,
                   !syncError.isEmpty,
                   wishlistManager.syncState == .failed {
                    Text(syncError)
                        .font(.caption)
                        .foregroundStyle(LiquidGlassTheme.Colors.neonError)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var authStatusTitle: String {
        switch wishlistManager.steamAuthState {
        case .signedIn:
            return L10n.tr("wishlist.auth_signed_in", fallback: "Signed in to Steam")
        case .notSignedIn:
            return L10n.tr("wishlist.auth_not_signed_in", fallback: "Not signed in")
        case .unknown:
            return L10n.tr("wishlist.auth_unknown", fallback: "Steam status unknown")
        }
    }

    private var authStatusIcon: String {
        switch wishlistManager.steamAuthState {
        case .signedIn:
            return "checkmark.shield.fill"
        case .notSignedIn:
            return "xmark.shield"
        case .unknown:
            return "questionmark.shield"
        }
    }

    private var authStatusColor: Color {
        switch wishlistManager.steamAuthState {
        case .signedIn:
            return LiquidGlassTheme.Colors.neonSuccess
        case .notSignedIn:
            return LiquidGlassTheme.Colors.neonWarning
        case .unknown:
            return .secondary
        }
    }

    private var syncStateLabel: String {
        switch wishlistManager.syncState {
        case .idle:
            return L10n.tr("wishlist.sync_state_idle", fallback: "Idle")
        case .syncing:
            return L10n.tr("wishlist.sync_state_syncing", fallback: "Syncing")
        case .synced:
            return L10n.tr("wishlist.sync_state_synced", fallback: "Synced")
        case .failed:
            return L10n.tr("wishlist.sync_state_failed", fallback: "Failed")
        }
    }
}

struct WishlistRow: View {
    let app: SteamApp
    @EnvironmentObject var wishlistManager: WishlistManager
    
    var body: some View {
        GlassCard(padding: 12) {
            HStack {
                WishlistCapsuleImage(imageURL: app.headerImageURL)
                    .frame(width: 112, height: 42)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                    
                    if let price = app.price {
                        HStack {
                            Text(price.formatted)
                                .font(.subheadline)
                                .foregroundStyle(LiquidGlassTheme.Colors.neonSuccess)
                            
                            if price.discountPercent > 0 {
                                Text("-\(price.discountPercent)%")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(LiquidGlassTheme.Colors.neonSuccess)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    wishlistManager.toggleWishlist(appID: app.id)
                } label: {
                    Image(systemName: wishlistManager.isWishlisted(appID: app.id) ? "heart.fill" : "heart")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(LiquidGlassTheme.Colors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(LiquidGlassTheme.Colors.neonSecondary.opacity(0.22), in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.tr("wishlist.toggle", fallback: "Toggle wishlist"))
            }
        }
    }
}

private struct WishlistCapsuleImage: View {
    let imageURL: URL?

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
            case let .success(image):
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))
                    image
                        .resizable()
                        .scaledToFill()
                }
            case .failure:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Image(systemName: "gamecontroller.fill")
                            .foregroundStyle(.white.opacity(0.2))
                    )
            @unknown default:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
