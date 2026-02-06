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
            
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.wishlistedApps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("Your wishlist is empty")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        WebFallbackShellView(url: URL(string: "https://store.steampowered.com/wishlist/")!, title: "Steam Wishlist")
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.text.square")
                            Text("Open Steam Wishlist (Web)")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.wishlistedApps) { app in
                            NavigationLink(value: app) {
                                WishlistRow(app: app)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Wishlist")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    WebFallbackShellView(url: URL(string: "https://store.steampowered.com/login/")!, title: "Sign in with Steam")
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
                    WebFallbackShellView(url: URL(string: "https://store.steampowered.com/wishlist/")!, title: "Steam Wishlist")
                } label: {
                    Image(systemName: "safari")
                }
            }
        }
        .alert("Steam Sync", isPresented: $viewModel.showSyncAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.syncAlertMessage)
        }
        .task {
            await viewModel.loadWishlist()
        }
    }
}

struct WishlistRow: View {
    let app: SteamApp
    
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
                
                Image(systemName: "heart.fill")
                    .foregroundStyle(LiquidGlassTheme.Colors.neonSecondary)
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
