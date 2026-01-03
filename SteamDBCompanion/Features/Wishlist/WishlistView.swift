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
